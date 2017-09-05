package main

import (
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"log"
	"os"
)

func main() {
	if len(os.Args) != 2 {
		log.Fatal("Must supply a filename as a parameter")
	}

	f, err := os.Open(os.Args[1]) // For read access.
	if err != nil {
		log.Fatal("Cannot open file")
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		log.Fatal(err)
	}

	fmt.Printf("sha2:%s\n", base64.StdEncoding.EncodeToString(h.Sum(nil)))
}
