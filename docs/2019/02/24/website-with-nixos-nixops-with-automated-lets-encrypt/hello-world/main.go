package main

import (
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", rootHandler)

	fmt.Println("Serving on port :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	host, err := os.Hostname()
	if err != nil {
		log.Printf("error getting the hostname: %s", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	if err := indexTemplate.Execute(w, struct{ Hostname string }{Hostname: host}); err != nil {
		log.Printf("error executing the index template: %s", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

var indexTemplate = template.Must(template.New("index.html").Parse(`
<!DOCTYPE html>
<html>
	<head>
		<title>Load-balanced application</title>
	</head>
	<body>
		<h1>Hello, World!</h1>
		<p>You are being serve this webpage from <strong>{{ .Hostname }}</strong>.</p>
	</body>
</html>
`))
