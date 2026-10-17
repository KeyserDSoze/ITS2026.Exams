var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<TaskItem> { new(1, "Preparare report", false) };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/tasks", () => Results.Ok(entries));

app.MapPost("/api/tasks", (CreateTaskItem request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Name.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapPatch("/api/tasks/{id:int}", (int id, UpdateState request) =>
{
    // TODO 5: cercare l'elemento tramite id. Se assente: HTTP 404.
    // TODO 6: creare una copia con Done = request.State,
    // salvarla nella lista e rispondere HTTP 200 con JSON.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record TaskItem(int Id, string Name, bool Done);
record CreateTaskItem(string? Name);
record UpdateState(bool State);
