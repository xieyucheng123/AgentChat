from typing import Optional, Type
from langchain_core.language_models import BaseChatModel
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnableSerializable
from pydantic import BaseModel

from agentchat.core.models.manager import ModelManager


class StructuredResponseAgent:
    def __init__(self, response_format: Type[BaseModel], model: Optional[BaseChatModel] = None):
        self.response_format = response_format
        # 如果没有传入模型，则使用工具调用模型
        self.model = model or ModelManager.get_tool_invocation_model()
        
        # 调试：打印模型配置
        print(f"🔧 StructuredResponseAgent使用的模型配置:")
        print(f"   模型类型: {type(self.model).__name__}")
        if hasattr(self.model, 'model_name'):
            print(f"   模型名称: {self.model.model_name}")
        if hasattr(self.model, 'base_url'):
            print(f"   基础URL: {self.model.base_url}")
        if hasattr(self.model, 'api_key') and self.model.api_key:
            print(f"   API密钥: {self.model.api_key[:20]}...")
        print()

    def get_structured_response(self, messages) -> BaseModel:
        # 提取最新的用户消息作为输入
        latest_message = ""
        for msg in reversed(messages):
            if hasattr(msg, 'content') and hasattr(msg, 'type') and msg.type == 'human':
                latest_message = msg.content
                break
        
        parser = PydanticOutputParser(pydantic_object=self.response_format)
        prompt_template = PromptTemplate(
            template="{prompt}\n{format_instructions}",
            input_variables=["prompt"],
            partial_variables={"format_instructions": parser.get_format_instructions()},
        )
        chain: RunnableSerializable = prompt_template | self.model | parser
        return chain.invoke({"prompt": latest_message})