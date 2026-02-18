package com.artac.app.controller;

import com.artac.app.model.HealthResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@RestController
public class AppController {

	@GetMapping("/")
	public ResponseEntity<String> home() {
		return ResponseEntity.ok("Welcome to ArtAc DevOps Demo Application");
	}

	@GetMapping("/api/health")
	public ResponseEntity<HealthResponse> health() {
		return ResponseEntity.ok(new HealthResponse("UP", Instant.now().toString()));
	}
}
