package com.artac.app.controller;

import com.artac.app.model.HealthResponse;
import org.springframework.boot.info.BuildProperties;
import org.springframework.boot.info.GitProperties;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Optional;

@RestController
public class AppController {

	private final Optional<BuildProperties> buildProperties;
	private final Optional<GitProperties> gitProperties;

	public AppController(
			Optional<BuildProperties> buildProperties,
			Optional<GitProperties> gitProperties) {
		this.buildProperties = buildProperties;
		this.gitProperties = gitProperties;
	}

	@GetMapping("/")
	public ResponseEntity<String> home() {
		return ResponseEntity.ok("Welcome to ArtAc DevOps Demo Application");
	}

	@GetMapping("/api/health")
	public ResponseEntity<HealthResponse> health() {
		return ResponseEntity.ok(new HealthResponse(
			"UP",
			Instant.now().toString(),
			buildProperties.map(BuildProperties::getVersion).orElse("unknown"),
			gitProperties.map(GitProperties::getShortCommitId).orElse("unknown"),
			gitProperties.map(GitProperties::getBranch).orElse("unknown")
		));
	}
}
