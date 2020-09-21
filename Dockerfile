FROM maartene/movezig:0.0.1
ENV ENVIRONMENT=production
ENTRYPOINT ./Run serve --hostname 0.0.0.0 --port 8080