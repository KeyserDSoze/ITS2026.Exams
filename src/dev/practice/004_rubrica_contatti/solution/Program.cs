var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Contact> { new(1, "Ada Lovelace", "ada@example.test") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/contacts", () => Results.Ok(entries));

app.MapPost("/api/contacts", (CreateContact request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });
    var email = request.Email?.Trim();
    if (string.IsNullOrWhiteSpace(email))
        return Results.BadRequest(new { error = "Email obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Contact(nextId, name, email);
    entries.Add(item);
    return Results.Created($"/api/contacts/{item.Id}", item);
});

app.Run();

record Contact(int Id, string Name, string Email);
record CreateContact(string? Name, string? Email);
