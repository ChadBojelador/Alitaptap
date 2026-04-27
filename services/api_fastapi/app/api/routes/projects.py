"""Student Projects API — Create / Read / Update / Delete."""

from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.core.mongodb import get_db

router = APIRouter(prefix="/projects", tags=["projects"])


class ProjectCreate(BaseModel):
    author_id: str
    title: str
    description: str
    sdg: str
    mode: str = "manual"          # "manual" | "ai"
    methodology: Optional[str] = None
    impact: Optional[str] = None
    feasibility: Optional[str] = None


class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    sdg: Optional[str] = None
    methodology: Optional[str] = None
    impact: Optional[str] = None
    feasibility: Optional[str] = None


class ProjectResponse(BaseModel):
    project_id: str
    author_id: str
    title: str
    description: str
    sdg: str
    mode: str
    methodology: str
    impact: str
    feasibility: str
    date: str


def _to_response(doc: dict) -> ProjectResponse:
    created = doc.get("created_at")
    date_str = (
        created.strftime("%Y-%m-%d")
        if hasattr(created, "strftime")
        else str(created or "")[:10]
    )
    return ProjectResponse(
        project_id=str(doc["_id"]),
        author_id=doc.get("author_id", ""),
        title=doc.get("title", ""),
        description=doc.get("description", ""),
        sdg=doc.get("sdg", ""),
        mode=doc.get("mode", "manual"),
        methodology=doc.get("methodology") or "",
        impact=doc.get("impact") or "",
        feasibility=doc.get("feasibility") or "",
        date=date_str,
    )


@router.post("", response_model=ProjectResponse)
def create_project(payload: ProjectCreate) -> ProjectResponse:
    db = get_db()
    data = {
        **payload.model_dump(),
        "created_at": datetime.now(timezone.utc),
    }
    result = db["student_projects"].insert_one(data)
    data["_id"] = result.inserted_id
    return _to_response(data)


@router.get("", response_model=list[ProjectResponse])
def list_projects(author_id: Optional[str] = None) -> list[ProjectResponse]:
    db = get_db()
    query = {"author_id": str(author_id)} if author_id else {}
    docs = db["student_projects"].find(query).sort("created_at", -1)
    return [_to_response(d) for d in docs]


@router.put("/{project_id}", response_model=ProjectResponse)
def update_project(project_id: str, payload: ProjectUpdate) -> ProjectResponse:
    db = get_db()
    doc = db["student_projects"].find_one({"_id": ObjectId(project_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="Project not found")
    updates = {k: v for k, v in payload.model_dump().items() if v is not None}
    if updates:
        db["student_projects"].update_one({"_id": ObjectId(project_id)}, {"$set": updates})
        doc = db["student_projects"].find_one({"_id": ObjectId(project_id)})
    return _to_response(doc)


@router.delete("/{project_id}")
def delete_project(project_id: str) -> dict:
    db = get_db()
    result = db["student_projects"].delete_one({"_id": ObjectId(project_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Project not found")
    return {"message": "Deleted", "project_id": project_id}
