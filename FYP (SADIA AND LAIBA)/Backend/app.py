import uuid
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
import urllib.parse
import os
from langchain_groq import ChatGroq
from langchain_community.embeddings import HuggingFaceBgeEmbeddings
from chatbot import Comsatsbot
# FastAPI app setup
app = FastAPI()

model_name = "BAAI/bge-small-en"
model_kwargs = {"device": "cpu"}
encode_kwargs = {"normalize_embeddings": True}
hf = HuggingFaceBgeEmbeddings(
    model_name=model_name, model_kwargs=model_kwargs, encode_kwargs=encode_kwargs
)

api_keys = [
    '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',
    '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',
    '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',
    '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',
]

llm = ChatGroq(temperature=0, groq_api_key=api_keys[2], model_name="llama3-70b-8192")

# MongoDB setup
username = 'laiba'
password = 'VRwiQ8padD_gN8t'
encoded_username = urllib.parse.quote_plus(username)
encoded_password = urllib.parse.quote_plus(password)
MONGODB_ATLAS_CLUSTER_URI = f'mongodb+srv://{encoded_username}:{encoded_password}@comsatsbot.04y7a.mongodb.net/'
client = MongoClient(MONGODB_ATLAS_CLUSTER_URI)
db = client.get_database('chat_db')  # Assume this is your database
chats_collection = db.get_collection('chats')  # Collection to store chats
paths = ['FYP Supervisor Feedback.csv', 'urdu_data.csv', 'english_data.csv']

chatbot = Comsatsbot(hf, llm, api_keys, chats_collection, paths)

# Endpoint for creating a new chat ID
@app.post("/get_new_chat")
def create_new_chat():
    try:
        chat_id = str(uuid.uuid4())
        message = chatbot.new_chat(chat_id)
        return {"chat_id": chat_id, "message": "Successfully created new chat."}
    except KeyError:
        raise HTTPException(status_code=404, detail="Chat ID already exist try again plz...")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Request model for response endpoint
class ChatRequest(BaseModel):
    chat_id: str
    question: str

# Endpoint for retrieving chat history by chat ID
@app.get("/get_chat/{chat_id}")
def get_chat(chat_id: str):
    try:
        history = chatbot.load_chat(chat_id)
        return {"chat_id": chat_id, "history": history}
    except KeyError:
        raise HTTPException(status_code=404, detail="Chat ID not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Endpoint for deleting a chat by chat ID
@app.delete("/delete_chat/{chat_id}")
def delete_chat(chat_id: str):
    try:
        message = chatbot.delete_chat(chat_id)
        return {"message": f"Chat with ID {chat_id} has been deleted successfully."}
    except KeyError:
        raise HTTPException(status_code=404, detail="Chat ID not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Endpoint for getting a response based on chat ID and question
@app.post("/response")
def response(request: ChatRequest):
    chat_id = request.chat_id
    question = request.question

    try:
        answer = chatbot.response(question, chat_id)
        return {"answer": answer}

    except KeyError:
        raise HTTPException(status_code=404, detail="Chat ID not found")

    except Exception as e:
        raise HTTPException(status_code=500, detail="GPU error, try after some time...")

