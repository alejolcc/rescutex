# Rescutex 🐾

Rescutex is an Elixir-based Phoenix application designed to help find lost pets through a combination of **geospatial searches** and **AI-driven image similarity**.

## 🌟 Key Features

- **Pet Matching:** Automatically matches lost and found pets based on physical proximity and visual appearance.
- **AI-Powered Search:** Uses Google Gemini (via `pgvector`) to generate and compare image embeddings for high-accuracy visual matching.
- **Geospatial Intelligence:** Leverages PostGIS to filter search results within a specific radius of a lost pet's last known location.
- **Real-time Interaction:** Built with Phoenix LiveView for a responsive, real-time user experience.
- **Asynchronous Pipeline:** Background jobs (via Oban) handle image processing and embedding generation without blocking the UI.

## 🛠 Tech Stack

- **Backend:** Elixir 1.19+, Phoenix 1.8.5+, Erlang/OTP 28.
- **Database:** PostgreSQL with:
  - **PostGIS:** For spatial queries.
  - **pgvector:** For vector similarity search.
- **Frontend:** Phoenix LiveView 1.0, Tailwind CSS.
- **AI Integration:** Google Gemini API for image processing and embeddings.
- **Infrastructure:** Tigris (AWS S3 compatible) for image storage, Oban for background jobs.

## 🚀 Getting Started

### Prerequisites

- Elixir and Erlang installed.
- PostgreSQL with PostGIS and pgvector (or use the provided Docker setup).
- A Google Gemini API Key.

## 📜 License

This project is licensed under the MIT License.
