from langchain_openai import ChatOpenAI
from langchain_core.tools import BaseTool
from typing import Union, Literal, Optional, Sequence, Any


class ModelArtsChat(ChatOpenAI):
    """
    ModelArts 平台兼容的 ChatOpenAI 子类
    
    主要功能：
    1. 适配 ModelArts 平台的 tool_choice 参数限制
    2. 保持与原生 ChatOpenAI 的完全兼容
    3. 不修改其他任何行为（流式响应、token 统计等）
    
    ModelArts 支持的 tool_choice 值：
    - "auto": 模型自动决定是否调用工具
    - "none": 不调用工具
    - "function": 必须调用工具
    
    不支持的值（会自动转换）：
    - "required" → "auto"
    - "any" → "auto"
    - 具名工具名称 → "auto"
    - True → "auto"
    """
    
    def bind_tools(
        self,
        tools: Sequence[Union[dict[str, Any], type, callable, BaseTool]],
        *,
        tool_choice: Optional[
            Union[dict, str, Literal["auto", "none", "required", "any"], bool]
        ] = None,
        strict: Optional[bool] = None,
        parallel_tool_calls: Optional[bool] = None,
        **kwargs: Any,
    ):
        """重写 bind_tools 方法以适配 ModelArts 平台"""
        
        # ModelArts 兼容性处理
        if tool_choice:
            original_tool_choice = tool_choice
            
            if isinstance(tool_choice, str):
                # 字符串类型的 tool_choice
                if tool_choice in ("required", "any"):
                    tool_choice = "auto"
                elif tool_choice not in ("auto", "none", "function"):
                    # 如果是具名工具名称，转换为 auto
                    tool_choice = "auto"
                    
            elif isinstance(tool_choice, bool):
                # 布尔值转换为 auto
                tool_choice = "auto"
            
            # 字典类型保持不变（可能是详细的工具配置）
            
            # 调试日志（可选）
            if original_tool_choice != tool_choice:
                import logging
                logger = logging.getLogger(__name__)
                logger.debug(
                    f"ModelArts 兼容调整："
                    f"tool_choice='{original_tool_choice}' -> '{tool_choice}'"
                )
        
        # 调用父类的 bind_tools 方法
        return super().bind_tools(
            tools,
            tool_choice=tool_choice,
            strict=strict,
            parallel_tool_calls=parallel_tool_calls,
            **kwargs
        )


__all__ = ["ChatOpenAI", "ModelArtsChat"]
