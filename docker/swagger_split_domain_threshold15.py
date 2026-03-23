import json
import re
from pathlib import Path
from collections import defaultdict

class SwaggerDomainSplitterOptimized:
    """Swagger 按业务域拆分器 - 优化版（合并小模块）"""
    
    def __init__(self, input_file, output_dir=None, min_apis_for_standalone=10):
        self.input_file = Path(input_file)
        self.output_dir = Path(output_dir) if output_dir else self.input_file.parent / 'split_optimized'
        self.output_dir.mkdir(exist_ok=True)
        self.min_apis_for_standalone = min_apis_for_standalone  # 独立文件的最小 API 数
        self.stats = {
            'total_paths': 0,
            'domains': {},
            'merged_small_domains': [],
            'schemas_count': 0
        }
    
    def extract_domain_from_tags(self, tags):
        """从 tags 提取业务域名"""
        if not tags or len(tags) == 0:
            return 'Common'
        
        tag = tags[0]
        domain = re.sub(r'[\u4e00-\u9fff]+', '', tag)
        domain = domain.replace('_', '_').strip('_')
        
        if not domain:
            domain = 'Domain_' + str(hash(tag))[:8]
        
        return domain if domain else 'Common'
    
    def split_by_domain(self):
        """按业务域拆分，自动合并小模块"""
        print(f"📂 Loading: {self.input_file}")
        
        with open(self.input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        paths = data.get('paths', {})
        self.stats['total_paths'] = len(paths)
        
        # 按 domain 分组 paths
        domain_paths = defaultdict(dict)
        domain_tags = defaultdict(set)
        
        print("\n🔍 Analyzing paths...")
        for path, path_item in paths.items():
            for method, operation in path_item.items():
                if method in ['get', 'post', 'put', 'delete', 'patch']:
                    if isinstance(operation, dict):
                        tags = operation.get('tags', [])
                        domain = self.extract_domain_from_tags(tags)
                        domain_paths[domain][path] = path_item
                        domain_tags[domain].update(tags)
                        
                        if domain not in self.stats['domains']:
                            self.stats['domains'][domain] = 0
                        self.stats['domains'][domain] += 1
        
        # 识别大模块和小模块
        large_domains = {}
        small_domains = {}
        
        for domain, count in self.stats['domains'].items():
            if count >= self.min_apis_for_standalone:
                large_domains[domain] = count
            else:
                small_domains[domain] = count
        
        print(f"\n📊 Domain Statistics:")
        print(f"  Large domains (≥{self.min_apis_for_standalone} APIs): {len(large_domains)}")
        print(f"  Small domains (<{self.min_apis_for_standalone} APIs): {len(small_domains)}")
        
        # 合并小模块到 Others
        if small_domains:
            merged_others = {}
            others_tags = set()
            
            for domain in small_domains:
                merged_others.update(domain_paths[domain])
                others_tags.update(domain_tags[domain])
                self.stats['merged_small_domains'].append(domain)
            
            # 创建合并后的 Others 文件
            self._create_domain_file(
                'Others',
                merged_others,
                others_tags,
                data,
                is_others=True
            )
            
            print(f"\n📦 Merged {len(small_domains)} small domains into 'Others'")
        
        # 为大模块生成独立文件
        print(f"\n✂️  Splitting {len(large_domains)} large domains...")
        
        for domain, count in sorted(large_domains.items(), key=lambda x: x[1], reverse=True):
            self._create_domain_file(
                domain,
                domain_paths[domain],
                domain_tags[domain],
                data
            )
        
        # 生成汇总报告
        report_file = self.output_dir / 'SPLIT_REPORT.md'
        self._generate_report(report_file, data, large_domains, small_domains)
        
        total_files = len(large_domains) + (1 if small_domains else 0)
        print(f"\n🎉 Split complete! Generated {total_files} files.")
        print(f"📄 Output dir: {self.output_dir}")
        
        return self.output_dir
    
    def _create_domain_file(self, domain_name, path_items, tags_set, original_data, is_others=False):
        """创建单个业务域文件"""
        domain_data = {
            'openapi': original_data.get('openapi', '3.0.0'),
            'info': original_data.get('info', {}),
            'servers': original_data.get('servers', []),
            'paths': path_items,
            'tags': [{'name': tag, 'description': f'{tag} API'} for tag in sorted(tags_set)],
            'components': {
                'schemas': {}
            }
        }
        
        # 收集引用的 schemas
        domain_json = json.dumps(domain_data, ensure_ascii=False)
        referenced_schemas = set(re.findall(r'\$ref":\s*"#/components/schemas/([^"]+)"', domain_json))
        
        # 复制 schemas
        all_schemas = original_data.get('components', {}).get('schemas', {})
        for schema_name in referenced_schemas:
            if schema_name in all_schemas:
                domain_data['components']['schemas'][schema_name] = all_schemas[schema_name]
        
        # 保存文件
        filename = f'swagger-{domain_name}.json' if not is_others else 'swagger-Others.json'
        output_file = self.output_dir / filename
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(domain_data, f, indent=2, ensure_ascii=False)
        
        file_size = output_file.stat().st_size
        api_count = len(path_items)
        print(f"  ✅ {domain_name}: {api_count} APIs, {len(referenced_schemas)} schemas, {file_size/1024:.1f}KB")
        
        self.stats['schemas_count'] += len(domain_data['components']['schemas'])
    
    def _generate_report(self, report_file, original_data, large_domains, small_domains):
        """生成拆分报告"""
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("# Swagger 按业务域拆分报告（优化版 - 阈值=15）\n\n")
            f.write(f"## 基本信息\n\n")
            f.write(f"- 原始文件：{self.input_file.name}\n")
            f.write(f"- 原始大小：{self.input_file.stat().st_size / 1024:.1f} KB\n")
            f.write(f"- 总 API 数：{self.stats['total_paths']}\n")
            f.write(f"- 独立业务域：{len(large_domains)} 个\n")
            f.write(f"- 合并小模块：{len(small_domains)} 个 → Others\n")
            f.write(f"- 总文件数：{len(large_domains) + (1 if small_domains else 0)}\n\n")
            
            f.write("## 大型业务域（独立文件）\n\n")
            f.write("| 业务域 | API 数量 | 占比 |\n")
            f.write("|--------|---------|------|\n")
            
            total_large = sum(large_domains.values())
            for domain, count in sorted(large_domains.items(), key=lambda x: x[1], reverse=True):
                percentage = (count / self.stats['total_paths'] * 100)
                f.write(f"| {domain} | {count} | {percentage:.1f}% |\n")
            
            f.write(f"\n## 合并的小模块（Others 文件）\n\n")
            f.write(f"共 {len(small_domains)} 个小模块，每个 < {self.min_apis_for_standalone} 个 API:\n\n")
            
            for domain, count in sorted(small_domains.items(), key=lambda x: x[1], reverse=True):
                f.write(f"- {domain}: {count} APIs\n")
            
            f.write(f"\n## 使用建议\n\n")
            f.write("### 高频核心模块（优先加载）\n\n")
            top_domains = sorted(large_domains.items(), key=lambda x: x[1], reverse=True)[:5]
            for domain, count in top_domains:
                f.write(f"- **{domain}**: {count} APIs - 核心业务功能\n")
            
            f.write(f"\n### MCP 服务器启动示例\n\n")
            f.write("```bash\n")
            for domain, _ in sorted(large_domains.items(), key=lambda x: x[1], reverse=True)[:3]:
                f.write(f"# 启动 {domain} 服务\n")
                f.write(f"npx apifox-mcp-server --oas swagger-{domain}.json\n\n")
            
            if small_domains:
                f.write(f"# 启动 Others 服务（包含 {len(small_domains)} 个小模块）\n")
                f.write(f"npx apifox-mcp-server --oas swagger-Others.json\n")


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Swagger 按业务域拆分工具（优化版）')
    parser.add_argument('input', help='输入的 Swagger JSON 文件路径')
    parser.add_argument('-o', '--output', help='输出目录（可选）')
    parser.add_argument('-m', '--min-apis', type=int, default=10, 
                       help='独立文件的最小 API 数（默认 10）')
    args = parser.parse_args()
    
    splitter = SwaggerDomainSplitterOptimized(args.input, args.output, args.min_apis)
    output_dir = splitter.split_by_domain()
    print(f"\n💡 提示：拆分后的文件位于 {output_dir}")
