from fastapi import APIRouter

router = APIRouter(prefix="/api/v1")

from .auth import user_router
router.include_router(user_router)

