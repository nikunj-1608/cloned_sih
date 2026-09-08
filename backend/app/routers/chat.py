from fastapi import APIRouter

from ..dependencies import RouterDep
from ..schemas.chat import ChatRequest, ChatResponse

router = APIRouter(prefix="/v1", tags=["assistant"])


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, intent_router: RouterDep) -> ChatResponse:
    """Ask the assistant a question.

    > [!IMPORTANT]
    > The response schema is a contract shared by all three tracks. Phase 2
    > answers from a deterministic keyword router (`engine="rules"`); Phase 4
    > swaps in the LangGraph swarm (`engine="langgraph"`) behind the identical
    > schema. The frontend must not need to change.
    """
    return await intent_router.handle(request)
