package com.artac.app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ArtacAppApplicationTests {

	@LocalServerPort
	private int port;

	@Autowired
	private TestRestTemplate restTemplate;

	@Test
	void contextLoads() {
	}

	@Test
	void homeEndpoint_shouldReturnWelcomeMessage() {
		ResponseEntity<String> response = restTemplate.getForEntity(
			"http://localhost:" + port + "/", String.class);

		assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
		assertThat(response.getBody()).contains("Welcome to ArtAc");
	}

	@Test
	void healthEndpoint_shouldReturnUpWithBuildInfo() {
		ResponseEntity<String> response = restTemplate.getForEntity(
			"http://localhost:" + port + "/api/health", String.class);

		assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
		assertThat(response.getBody())
			.contains("\"status\":\"UP\"")
			.contains("\"timestamp\"");
	}

	@Test
	void actuatorHealth_shouldReturnUp() {
		ResponseEntity<String> response = restTemplate.getForEntity(
			"http://localhost:" + port + "/actuator/health", String.class);

		assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
		assertThat(response.getBody()).contains("\"status\":\"UP\"");
	}
}
