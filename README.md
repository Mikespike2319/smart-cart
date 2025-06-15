# MaxSaver Pro - Smart Grocery Price Comparison

MaxSaver Pro is an intelligent grocery price comparison app that helps users find the best deals across multiple stores. The app uses machine learning to predict price trends and provides personalized shopping recommendations.

## Features

- 🔍 Real-time price comparison across multiple stores
- 📊 Price history tracking and visualization
- 🤖 ML-powered price predictions
- 🏷️ Best deals and discounts
- 📱 Native iOS app with modern UI
- 🔔 Price alerts and notifications
- 📝 Smart shopping lists
- 🛒 Barcode scanning for quick product lookup

## Tech Stack

### Backend
- FastAPI (Python)
- PostgreSQL
- SQLAlchemy ORM
- scikit-learn for ML
- Docker & Docker Compose

### iOS App
- SwiftUI
- Combine
- Core Data
- AVFoundation (for barcode scanning)

### Infrastructure
- AWS (EKS, RDS, ElastiCache)
- Terraform
- GitHub Actions

## Getting Started

### Prerequisites
- Python 3.8+
- Xcode 14+
- Docker & Docker Compose
- PostgreSQL
- CocoaPods

### Backend Setup
```bash
# Clone the repository
git clone https://github.com/Mikespike2319/smart-cart.git
cd smart-cart

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
cd backend
pip install -r requirements.txt

# Start the services
docker-compose up -d

# Run the API server
uvicorn main:app --reload
```

### iOS App Setup
```bash
# Install CocoaPods if not already installed
sudo gem install cocoapods

# Install dependencies
cd ios
pod install

# Open the workspace in Xcode
open MaxSaverPro.xcworkspace
```

## API Documentation

Once the backend is running, you can access the API documentation at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Development

### Project Structure
```
smart-cart/
├── backend/
│   ├── api/
│   │   ├── models/
│   │   ├── routers/
│   │   ├── services/
│   │   └── schemas/
│   ├── tests/
│   └── main.py
├── ios/
│   ├── MaxSaverPro/
│   │   ├── Views/
│   │   ├── Models/
│   │   └── Services/
│   └── Podfile
└── infrastructure/
    └── terraform/
```

### Running Tests
```bash
# Backend tests
cd backend
pytest

# iOS tests
cd ios
xcodebuild test -workspace MaxSaverPro.xcworkspace -scheme MaxSaverPro
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [FastAPI](https://fastapi.tiangolo.com/)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [scikit-learn](https://scikit-learn.org/)
- [Terraform](https://www.terraform.io/) 