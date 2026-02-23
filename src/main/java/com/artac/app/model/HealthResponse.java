package com.artac.app.model;

public record HealthResponse(
    String status,
    String timestamp,
    String version,
    String gitCommit,
    String gitBranch
) {}
