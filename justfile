# Start frontend watch and backend watch in parallel
start:
    npm --prefix frontend run watch:purs &
    npm --prefix frontend run watch:css &
    cd backend && cargo watch -x run
