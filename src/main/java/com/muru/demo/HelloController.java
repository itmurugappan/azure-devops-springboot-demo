package com.muru.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

@RestController
public class HelloController {

    // Set per environment by the deploy step (Tomcat setenv / system properties):
    //   APP_ENV     e.g. DEV / SIT / PROD   (from the variable group)
    //   APP_VERSION e.g. the CI build number
    //   APP_API_KEY the Key Vault secret for that environment.
    //               We NEVER print its value - only that it loaded, and its length.
    private String env(String name, String fallback) {
        String v = System.getenv(name);
        if (v == null || v.isBlank()) {
            v = System.getProperty(name);
        }
        return (v == null || v.isBlank()) ? fallback : v;
    }

    @GetMapping("/")
    public String home() {
        String env = env("APP_ENV", "LOCAL");
        String version = env("APP_VERSION", "1.0.0");
        String secret = env("APP_API_KEY", "");
        String secretStatus = secret.isBlank()
                ? "NO"
                : "YES (length " + secret.length() + ")";
        String now = ZonedDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        return "<h1>Azure DevOps Demo</h1>"
                + "<p>Environment: <b>" + env + "</b></p>"
                + "<p>Build version: <b>" + version + "</b></p>"
                + "<p>Secret loaded from Key Vault: <b>" + secretStatus + "</b></p>"
                + "<p>Server time: " + now + "</p>";
    }

    @GetMapping("/health")
    public String health() {
        return "OK " + env("APP_ENV", "LOCAL") + " " + env("APP_VERSION", "1.0.0");
    }
}
