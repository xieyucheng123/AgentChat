import json
import re
import sys
from pathlib import Path

class SwaggerUltimateOptimizer:
    """Swagger 终极优化器 - 添加 operationId + 清理冗余"""
    
    def __init__(self, input_file, output_file=None):
        self.input_file = Path(input_file)
        self.output_file = Path(output_file) if output_file else None
        self.stats = {
            'original_size': 0,
            'optimized_size': 0,
            'operationIds_added': 0,
            'schemas_removed': 0,
            'responses_simplified': 0
        }
    
    def generate_operation_id(self, path, method, tags=None, summary=None):
        """生成符合规范的 operationId（仅英文）"""
        
        # 清理 path 中的参数
        clean_path = re.sub(r'\{[^}]+\}', '', path)
        clean_path = clean_path.strip('/')
        parts = [part for part in clean_path.split('/') if part]
        
        # 优先使用 tags 作为前缀（转换为英文）
        if tags and len(tags) > 0:
            # 移除中文，保留英文和数字
            tag_text = tags[0]
            tag_clean = re.sub(r'[\u4e00-\u9fff]+', '', tag_text)  # 移除中文
            tag_clean = tag_clean.replace('_', ' ').replace('-', ' ').title().replace(' ', '')
            prefix = tag_clean if tag_clean else 'Api'
        else:
            prefix = parts[0].title() if parts else 'Api'
        
        # 处理 method
        method_map = {
            'get': 'Get',
            'post': 'Create' if (summary and any(x in summary for x in ['Add', 'Create', '新增', '创建'])) else 'Post',
            'put': 'Update',
            'delete': 'Delete',
            'patch': 'Patch'
        }
        action = method_map.get(method.lower(), method.title())
        
        # 从 summary 提取动作（如果有英文）
        if summary:
            # 尝试提取第一个英文单词
            english_match = re.match(r'^([A-Za-z]+)', summary)
            if english_match:
                action = english_match.group(1).title()
        
        # 构建 operationId
        if parts:
            # 将每个部分转为 PascalCase
            resource_parts = []
            for part in parts:
                # 移除中文，保留英文和数字
                part_clean = re.sub(r'[\u4e00-\u9fff]+', '', part)
                if part_clean:
                    resource_parts.append(part_clean.title())
            
            if resource_parts:
                resource = ''.join(resource_parts)
                operation_id = f"{action}{resource}"
                
                # 添加参数后缀
                if '{' in path:
                    param_names = re.findall(r'\{([^}]+)\}', path)
                    for param in param_names:
                        operation_id += f"By{param.title()}"
            else:
                operation_id = f"{action}Resource"
        else:
            operation_id = action
        
        return operation_id
    
    def optimize(self):
        """执行完整优化"""
        print(f"🔄 Loading: {self.input_file}")
        
        with open(self.input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        self.stats['original_size'] = len(json.dumps(data))
        print(f"📊 Original size: {self.stats['original_size'] / 1024:.1f} KB")
        
        paths = data.get('paths', {})
        generated_ids = set()
        
        # 1. 添加 operationId
        print("\n🔧 Step 1: Adding operationId...")
        for path, path_item in paths.items():
            for method, operation in path_item.items():
                if method in ['get', 'post', 'put', 'delete', 'patch', 'options', 'head']:
                    if isinstance(operation, dict) and 'operationId' not in operation:
                        tags = operation.get('tags', [])
                        summary = operation.get('summary', '')
                        
                        base_id = self.generate_operation_id(path, method, tags, summary)
                        operation_id = base_id
                        
                        # Ensure uniqueness
                        counter = 1
                        while operation_id in generated_ids:
                            operation_id = f"{base_id}_{counter}"
                            counter += 1
                        
                        operation['operationId'] = operation_id
                        generated_ids.add(operation_id)
                        self.stats['operationIds_added'] += 1
        
        print(f"   ✅ Added {self.stats['operationIds_added']} operationIds")
        
        # 2. 简化 responses
        print("\n🔧 Step 2: Simplifying responses...")
        for path, path_item in paths.items():
            for method, operation in path_item.items():
                if isinstance(operation, dict) and 'responses' in operation:
                    for status_code, response in operation['responses'].items():
                        if isinstance(response, dict) and 'content' in response:
                            content_types = list(response['content'].keys())
                            if len(content_types) > 1 and 'application/json' in content_types:
                                response['content'] = {
                                    'application/json': response['content']['application/json']
                                }
                                self.stats['responses_simplified'] += 1
        
        print(f"   ✅ Simplified {self.stats['responses_simplified']} responses")
        
        # 3. 移除 .NET Type schemas
        print("\n🔧 Step 3: Removing .NET Type schemas...")
        schemas = data.get('components', {}).get('schemas', {})
        patterns_to_remove = [
            r'^Type$', r'^TypeInfo$', r'^MemberInfo$',
            r'CustomAttribute.*', r'MethodBase.*', r'PropertyInfo.*',
            r'FieldInfo.*', r'EventInfo.*', r'ParameterInfo.*'
        ]
        
        schemas_to_remove = []
        for schema_name in schemas.keys():
            if any(re.match(pattern, schema_name) for pattern in patterns_to_remove):
                schemas_to_remove.append(schema_name)
        
        for schema_name in schemas_to_remove:
            del schemas[schema_name]
            self.stats['schemas_removed'] += 1
        
        print(f"   ✅ Removed {self.stats['schemas_removed']} .NET Type schemas")
        
        # Save
        if not self.output_file:
            self.output_file = self.input_file.with_name(f"{self.input_file.stem}.optimized{self.input_file.suffix}")
        
        self.stats['optimized_size'] = len(json.dumps(data))
        compression = (1 - self.stats['optimized_size'] / self.stats['original_size']) * 100
        
        print(f"\n💾 Saving to: {self.output_file}")
        with open(self.output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"\n{'='*60}")
        print("✅ OPTIMIZATION COMPLETE!")
        print(f"{'='*60}")
        print(f"📊 Statistics:")
        print(f"  - Original size: {self.stats['original_size'] / 1024:.1f} KB")
        print(f"  - Optimized size: {self.stats['optimized_size'] / 1024:.1f} KB")
        print(f"  - Compression rate: {compression:.1f}%")
        print(f"  - OperationIds added: {self.stats['operationIds_added']}")
        print(f"  - Responses simplified: {self.stats['responses_simplified']}")
        print(f"  - Schemas removed: {self.stats['schemas_removed']}")
        print(f"  - API operations: {len(paths)}")
        
        return data


def main():
    if len(sys.argv) < 2:
        print("Usage: python optimize_complete.py <swagger.json> [output.json]")
        print("\nExample:")
        print("  python optimize_complete.py swagger.json")
        print("  python optimize_complete.py swagger.json swagger.final.json")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    optimizer = SwaggerUltimateOptimizer(input_file, output_file)
    optimizer.optimize()
    
    print(f"\n🚀 Start MCP Server:")
    print(f"   npx apifox-mcp-server --oas \"{optimizer.output_file.absolute()}\" --transport http --port 3000")


if __name__ == "__main__":
    main()

