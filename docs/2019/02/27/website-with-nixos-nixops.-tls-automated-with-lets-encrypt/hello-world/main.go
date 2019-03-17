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

	// create the data that is going to be used for the template. This might look
	// confusing, but it's creating a struct value from an anonymous struct.
	// it can also be written on one line, more preferrable:
	//
	//   data := struct{ Hostname string }{Hostname: host}
	//
	data := struct {
		Hostname string
	}{
		Hostname: host,
	}

	if err := indexTemplate.Execute(w, data); err != nil {
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
