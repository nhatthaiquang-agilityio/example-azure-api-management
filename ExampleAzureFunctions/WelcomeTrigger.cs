using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using System.Net;

namespace ExampleAzureFunctions
{
    public class WelcomeTrigger
    {
        private readonly ILogger<WelcomeTrigger> _logger;

        public WelcomeTrigger(ILogger<WelcomeTrigger> logger)
        {
            _logger = logger;
        }

        [Function("Welcome")]
        [OpenApiOperation(operationId: "WelcomeTrigger")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(string),
            Description = "The OK response message.")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            return new OkObjectResult("Welcome to Azure Functions!");
        }
    }
}
