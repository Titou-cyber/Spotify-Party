# Spotify-Party

    cd .\backend\

    python -m venv venv

    .\venv\Scripts\activate

    pip install -r requirements.txt

    cd ..

    cd .\mobile_app\

    flutter build web  

    cd ..

    cd .\backend\

    python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000