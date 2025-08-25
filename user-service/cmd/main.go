// cmd/main.go
package main

import (
	"kube-openwebui/user-service/internal/database"
	"kube-openwebui/user-service/internal/handlers"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize database connection
	database.Connect()

	// Set up Gin router
	r := gin.Default()

	// Public routes
	public := r.Group("/api/v1/auths")
	{
		public.POST("/signup", handlers.RegisterHandler) // Matches open-webui's /signup
		public.POST("/signin", handlers.LoginHandler)   // Matches open-webui's /signin
	}

	// Example of a protected route group
	// protected := r.Group("/api/v1/users")
	// protected.Use(handlers.AuthMiddleware())
	// {
	//     // Add routes here that require authentication
	// }

	// Start server
	if err := r.Run(":8000"); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
