var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Announcement> { new(1, "Riunione di classe", false) };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/announcements", () => Results.Ok(entries));

app.MapPost("/api/announcements", (CreateAnnouncement request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Title.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapPatch("/api/announcements/{id:int}", (int id, UpdateState request) =>
{
    // TODO 5: cercare l'elemento tramite id. Se assente: HTTP 404.
    // TODO 6: creare una copia con Published = request.State,
    // salvarla nella lista e rispondere HTTP 200 con JSON.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.MapDelete("/api/announcements/{id:int}", (int id) =>
{
    // TODO: cercare l'id; se non esiste -> HTTP 404.
    // TODO: cancellare il record e rispondere HTTP 204 (NoContent).
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Announcement(int Id, string Title, bool Published);
record CreateAnnouncement(string? Title);
record UpdateState(bool State);
