using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using StackExchange.Redis;

namespace redis_cache_web_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EmployeeController : ControllerBase
{
    private static readonly string[] Summaries = new[]
    {
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
    };
    private readonly IConfiguration _configuration;

    private readonly ILogger<WeatherForecastController> _logger;
    private static RedisConnection _redisConnection;

    public EmployeeController(ILogger<WeatherForecastController> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
        //Console.WriteLine($"This is the connection **{_configuration.GetValue<string>("CacheConnection")}**");
        _redisConnection = RedisConnection.InitializeAsync(_configuration.GetValue<string>("CacheConnection")).Result;
    }

    [HttpGet("{id}",Name = "GetEmployee")]
    public async Task<ActionResult<Employee>> GetEmployee(string id)
    {
        RedisValue getMessageResult = await _redisConnection.BasicRetryAsync(async (db) => await db.StringGetAsync($"e{id}"));
        Employee fromCache = JsonSerializer.Deserialize<Employee>(getMessageResult.ToString());
        Employee em = new Employee(fromCache?.Id, fromCache?.Name, fromCache?.Age ?? default(int));

        return em;
    }

    [HttpPost]
    public async Task<ActionResult<Employee>> PostEmployee(Employee emp)
    {
        await _redisConnection.BasicRetryAsync(async (db) => await db.StringSetAsync($"e{emp.Id}", JsonSerializer.Serialize(emp)));

        return emp;
    }
}
