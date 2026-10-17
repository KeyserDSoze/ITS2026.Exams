var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Course> { new(1, "Fondamenti di C#") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/courses", () => Results.Ok(entries));

app.MapPost("/api/courses", (CreateCourse request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Title.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapPut("/api/courses/{id:int}", (int id, CreateCourse request) =>
{
    // TODO 5: validare Title; se manca tornare HTTP 400.
    // TODO 6: cercare il record per id; se manca tornare HTTP 404.
    // TODO 7: aggiornare Title e tornare HTTP 200 con JSON.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapDelete("/api/courses/{id:int}", (int id) =>
{
    // TODO: cercare l'id; se non esiste -> HTTP 404.
    // TODO: cancellare il record e rispondere HTTP 204 (NoContent).
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Course(int Id, string Title);
record CreateCourse(string? Title);
