import os
from groq import Groq
from langchain.memory import ConversationTokenBufferMemory
from langdetect import detect
from deep_translator import GoogleTranslator
from langchain_community.document_loaders.csv_loader import CSVLoader
from langchain_community.vectorstores import FAISS
import time
import json

class Comsatsbot:
    def __init__(self, hf, llm, api_keys, chats_collection, paths, index_path='faiss_kb'):
        self.llm = llm
        self.api_keys = api_keys
        self.client = None
        self.models = ["llama3-groq-70b-8192-tool-use-preview", "llama-3.1-70b-versatile", "llama3-70b-8192"]


        # Initialize memory buffer and MongoDB connection
        self.memory = ConversationTokenBufferMemory(llm=self.llm, max_token_limit=3000)
        self.chats_collection = chats_collection
        self.index_path = index_path
        self.hf = hf
        self.faiss_index = None
        self.faiss_retriever = None
        self.paths = paths
        self.initialize_faiss_index()

    def load_data(self, paths):
        documents = []
        for path in paths:
            loader = CSVLoader(file_path=path)
            data = loader.load()
            documents.extend(data)
        return documents

    def initialize_faiss_index(self):
        if os.path.exists(self.index_path):
            self.faiss_index = FAISS.load_local(self.index_path, self.hf, allow_dangerous_deserialization=True)
            self.faiss_retriever = self.faiss_index.as_retriever(search_kwargs={"k": 5})
        else:
            documents = self.load_data(self.paths)
            self.faiss_index = FAISS.from_documents(documents, self.hf)
            self.faiss_index.save_local(self.index_path)
            self.faiss_retriever = self.faiss_index.as_retriever(search_kwargs={"k": 5})

    def retrieve_answer(self, query):
        if self.faiss_retriever:
            return self.faiss_retriever.invoke(query)
        else:
            print("FAISS retriever is not initialized. Please create or load an index.")
            return None

    def create_chat_record(self, chat_id):
        self.chats_collection.insert_one({
            "_id": chat_id,
            "history": []
        })

    def update_chat(self, chat_id, question, answer):
        self.chats_collection.update_one(
            {"_id": chat_id},
            {"$push": {"history": {"question": question, "answer": answer}}}
        )

    def load_chat(self, chat_id):
        chat_record = self.chats_collection.find_one({"_id": chat_id})
        if not chat_record:
            raise KeyError(f"Chat ID {chat_id} does not exist.")
        return chat_record.get('history', [])

    def new_chat(self, chat_id):
        # Check if chat ID already exists
        if self.chats_collection.find_one({"_id": chat_id}):
            raise KeyError(f"Chat ID {chat_id} exist already.")

        # Create a new chat record if it doesn't exist
        self.create_chat_record(chat_id)
        return "success"

    def delete_chat(self, chat_id):
        # Check if the chat ID exists
        if not self.chats_collection.find_one({"_id": chat_id}):
            raise KeyError(f"Chat ID {chat_id} does not exist.")

        # Delete the chat if it exists
        self.chats_collection.delete_one({"_id": chat_id})
        return "success"

    def generate_response(self, question, history, context):

        prompt = f'''
                 Kindly use the proper emojis where we need to use in  responses.       
                You are an comsats assistant to help the user related to comsats university, conversation, studies related query. Your answer should be very concise and to the point short answer. Dont need to repeat irrelevant text. 
                Answer the following Question: {question}
                Kindly use the proper emojis where we need to use in responses.
                Kindly generate a concise and to the point answer. Kindly answer the question from the provided context and if you dont find the answer from chat histoy and context then inform the user i dont know and dont make the answer from yourself.
                Dont need to mention that (according to provided context/Based on the provided chat history) in response and just generate the response just like human without mention this according to context and chat history.
                You are a conversational and helpfull agent to help the comsats university attock campus students, and your task is to provide concise and direct answers to the questions.
                Your task is to use the emoji when there is happy, sad, surprise, angry expression required in response. Kindly analyze the question and if expression is required in response then use the emoji otherwise dont use the emoji and remember that you dont need to use the emoji in simple studies and comstas related question.
                For example user ask same question again and again, user is not understanding anything, user asking wrong things etc then your task is to use the emoji in such response and be choosy in using emoji in response in happy sad angry response according to user question.
                If there is any need to provide the url and then kindly generate the url according to following structure. Kindly provide the link clickable. Your provided should be generated according to following structure 
                [Click here to visit "website name"](website url "https://comsats.edu.pk" write the same url as it is provided in context below and dont use the www in url and use the same link url as it provided in context(admssion detail: (http://admissions.comsats.edu.pk/Home/EligibilityCriteria?pt=BS)))
                Dont need to explain and repeat the prompt in response.
                1. Kindly generate a full concise answer and if you dont find answer from context and chathistoyr then dont need to make the answer just answer it in i dont know.
                2. Dont need to explain irrelevant explanation and use the proper emojis in answer if required in responses.
                3. Always respond in a human-like tone and keep your answers concise, to the point and friendly.
                4. If the question is conversational (like greetings, need any converstaion, help related studies, knowledge base question etc), respond in a warm, conversational tone.
                5. Always consider the provided context and chat history to formulate your response.
                6. If you don’t know the answer to the provided question or you did not find the answer from the context and chat history, kindly respond with "I don't know the answer to this.emooji" without adding irrelevant text explanations.
                7. Kindly generate a perfect and to the point  and short answer. Dont use any irrelevant text explanation and i want full concise and to the point answer.
                 Kindly use the proper emojis where we need to use in  responses.
                Question: {question}
                Kindly answer the question from the provided context and if you dont find the answer from chat histoy and context then inform the user i dont know and dont make the answer from yourself.
                Use the following context to answer and dont mention that you are answer from this tcontext in response:
                Comsats Attock Campus Provide BSomputerScience, BSSoftwareEngineer BSArtificialIntelligence BSEnglish BSmath BSElectricalEngineering BSComputerEngineering BSBBA 
                Has three departments CS(CS, AI, SE), Math(math, BBA, english) and EE(EE, CE).
                It has cricket ground and football ground and two canteens. First near math and ee department and second near cs department. There is also mosque near cs department. CS department has threater liker rooms lt and total 9 theaters called lt and math has classroom cr and ee has labs.
                They accept the nts test for admission and provide the cgpa for 4 on 85 percent and 3.66 between 79 to 84 and many more. 
                
                
                {context}
                Context is ending 
                Now here is chat history that you have to consider and identify
                **Consider the following chat history for additional context to answer the question:** 
                {history}
                Answer the following Question: {question}
                '''
        while True:
            for api_key in self.api_keys:
                self.client = Groq(api_key=api_key)

                for model in self.models:
                    try:
                        chat_completion = self.client.chat.completions.create(
                        messages=[
                              {
                    "role": "system",
                    "content": prompt,
                },
                {
                    "role": "user",
                    "content": f"Answer the following question : {question}",
                },
                        ],
                        model=model,
                        max_tokens=1024,
                    )

                        response_content = chat_completion.choices[0].message.content
                        return response_content
                    except Exception as e:
                        time.sleep(2)

                        continue

            return "Sorry, unable to provide an answer at this time."

    def detect_language(self, question):

        while True:
            for api_key in self.api_keys:
                self.client = Groq(api_key=api_key)
    
                for model in self.models:
                    try:
                        chat_completion = self.client.chat.completions.create(
                        messages=[
                            {
                    "role": "system",
                    "content": """ 
                    You are an expert agent and your task is to detect the language from the following provided question. Your generated output should be according to following json format.
                    Json Output Format:
                    {'detected_language': 'write the just detected language name: urdu, english '}


                    
                    """,
                },
                {
                    "role": "user",
                    "content": f"detect the language for the following Question: {question}",
                },
                        ],
                        model=model,
                        max_tokens=512,
                        response_format={"type": "json_object"},
                    )
    
                        response_content = chat_completion.choices[0].message.content
                        json_response = json.loads(response_content)
                        return json_response['detected_language'].lower()
                    except Exception as e:
                        time.sleep(2)
    
                        continue
    def translate_urdu(self, text):

        while True:
            for api_key in self.api_keys:
                self.client = Groq(api_key=api_key)
    
                for model in self.models:
                    try:
                        chat_completion = self.client.chat.completions.create(
                        messages=[
                            {
                    "role": "system",
                    "content": """ 
                    You are an expert agent and your task is to translayte the following text in in proper urdu text and i want corrected urdu and dont need to add irrelevant text. Your generated output should be according to following json format.
                    Json Output Format:
                    {'text': 'write the just translated urdu text here and dont need to add irrelevant text'}


                    
                    """,
                },
                {
                    "role": "user",
                    "content": f"detect the language for the following Question: {text}",
                },
                        ],
                        model=model,
                        max_tokens=512,
                        response_format={"type": "json_object"},
                    )
    
                        response_content = chat_completion.choices[0].message.content
                        json_response = json.loads(response_content)
                        return json_response['text']
                    except Exception as e:
                        time.sleep(2)
    
                        continue


    def response(self, question, chat_id):
        chat_history = self.load_chat(chat_id)

        # Load the previous conversation into memory
        for entry in chat_history:
            self.memory.save_context({"input": entry["question"]}, {"output": entry["answer"]})

        language = self.detect_language(question)
        if language == 'urdu':
            question_translation = GoogleTranslator(source='ur', target='en').translate(question)
            context = self.faiss_retriever.invoke(question_translation)
        else:
            context = self.faiss_retriever.invoke(question)

        all_content = ''
        for document in context:
            page_content = document.page_content
            all_content += page_content + '\n' 
        answer = self.generate_response(question, self.memory.load_memory_variables({})['history'], all_content)

        
        
        if language == 'urdu':
            translated_answer = self.translate_urdu(answer)
            self.update_chat(chat_id, question, answer)
            return translated_answer
        else:
            self.update_chat(chat_id, question, answer)
            return answer
            
            
        




