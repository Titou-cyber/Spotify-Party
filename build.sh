#!/bin/bash

echo "🚀 Starting build process..."

# Build Flutter Web
echo "📱 Building Flutter app..."
cd mobile_app
flutter pub get
flutter build web --release
cd ..

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
cd backend
pip install -r requirements.txt
cd ..

echo "✅ Build complete!"