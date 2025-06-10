package com.bhuang.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class WeatherServiceTest {

    @Autowired
    private WeatherService weatherService;

    @Test
    void testGetWeatherForecastByCity() {
        // 测试支持的城市
        String result = weatherService.getWeatherForecastByCity("Seattle, WA");
        assertNotNull(result);
        assertFalse(result.contains("Sorry, I don't have coordinates"));
        assertTrue(result.contains("Weather Forecast"));
    }

    @Test
    void testGetWeatherForecastByCityUnsupported() {
        // 测试不支持的城市
        String result = weatherService.getWeatherForecastByCity("Unknown City");
        assertNotNull(result);
        assertTrue(result.contains("Sorry, I don't have coordinates"));
    }

    @Test
    void testGetWeatherForecastByLocation() {
        // 测试西雅图的坐标
        String result = weatherService.getWeatherForecastByLocation(47.6062, -122.3321);
        assertNotNull(result);
        assertTrue(result.contains("Weather Forecast for 47.6062, -122.3321"));
    }

    @Test
    void testGetCurrentWeather() {
        // 测试获取当前天气
        String result = weatherService.getCurrentWeather(47.6062, -122.3321);
        assertNotNull(result);
        assertTrue(result.contains("Current Weather for"));
    }

    @Test
    void testGetAlerts() {
        // 测试获取华盛顿州的天气警报
        String result = weatherService.getAlerts("WA");
        assertNotNull(result);
        // 结果应该包含警报信息或者"No active weather alerts"
        assertTrue(result.contains("Event:") || result.contains("No active weather alerts"));
    }
}