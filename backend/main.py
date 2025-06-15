from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from strawberry.fastapi import GraphQLRouter
from typing import List, Optional
import uvicorn
import logging
from datetime import datetime
from api.routers import auth, products, shopping_lists, price_comparison
from api.database import engine, Base

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="MaxSaver Pro API",
    description="API for MaxSaver Pro grocery price comparison app",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

# GraphQL schema and resolvers will be imported here
# from api.graphql.schema import schema
# graphql_app = GraphQLRouter(schema)
# app.include_router(graphql_app, prefix="/graphql")

# Create database tables
Base.metadata.create_all(bind=engine)

# Include routers
app.include_router(auth.router)
app.include_router(products.router)
app.include_router(shopping_lists.router)
app.include_router(price_comparison.router)

@app.get("/")
async def root():
    return {
        "message": "Welcome to MaxSaver Pro API",
        "version": "1.0.0",
        "docs_url": "/docs"
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True) 