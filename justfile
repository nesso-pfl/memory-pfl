# Start frontend watch and backend watch in parallel
start:
    npx --prefix frontend spago bundle --bundle-type app --outfile dist/app.js --watch &
    cd backend && cargo watch -x run
