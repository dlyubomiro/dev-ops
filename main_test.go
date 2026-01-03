package main

import (
	"log"
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gorilla/mux"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB() *gorm.DB {
	db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err := db.AutoMigrate(&Book{}); err != nil {
		log.Fatal("AutoMigrate failed:", err)
	}
	return db
}

func TestGetBooks(t *testing.T) {
	testDB := setupTestDB()
	db = testDB
	testDB.Create(&Book{Title: "Test Book", Author: "Test Author", ISBN: "123456"})
	req, _ := http.NewRequest("GET", "/books", nil)
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(getBooks)
	handler.ServeHTTP(rr, req)
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Expected status 200, got %d", status)
	}
}

func TestCreateBook(t *testing.T) {
	testDB := setupTestDB()
	db = testDB
	book := Book{Title: "New Book", Author: "New Author", ISBN: "789012"}
	jsonValue, _ := json.Marshal(book)
	req, _ := http.NewRequest("POST", "/books", bytes.NewBuffer(jsonValue))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(createBook)
	handler.ServeHTTP(rr, req)
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Expected status 200, got %d", status)
	}
}

func TestHealthCheck(t *testing.T) {
	req, _ := http.NewRequest("GET", "/health", nil)
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(healthCheck)
	handler.ServeHTTP(rr, req)
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Expected status 200, got %d", status)
	}
}

func TestGetBook(t *testing.T) {
	testDB := setupTestDB()
	db = testDB
	testBook := Book{Title: "Single Book", Author: "Single Author", ISBN: "111222"}
	testDB.Create(&testBook)
	req, _ := http.NewRequest("GET", "/books/1", nil)
	rr := httptest.NewRecorder()
	router := mux.NewRouter()
	router.HandleFunc("/books/{id}", getBook).Methods("GET")
	router.ServeHTTP(rr, req)
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Expected status 200, got %d", status)
	}
}
