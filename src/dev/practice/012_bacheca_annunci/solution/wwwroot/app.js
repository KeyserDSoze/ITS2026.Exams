const list = document.querySelector('#entries');
const form = document.querySelector('#entry-form');
const input = document.querySelector('#title');
const message = document.querySelector('#message');

async function loadEntries() {
  const response = await fetch('/api/announcements');
  if (!response.ok) throw new Error('Errore nel caricamento.');
  const entries = await response.json();
  list.replaceChildren();
  const filter = document.querySelector('#search').value.trim().toLowerCase();
  for (const entry of entries) {
    if (!entry.title.toLowerCase().includes(filter)) continue;
    const li = document.createElement('li');
    li.className = 'entry-card';
    const content = document.createElement('span');
    content.textContent = entry.title;
    li.appendChild(content);
    const badge = document.createElement('span');
    badge.className = 'status-badge';
    badge.textContent = entry.published ? 'Pubblicato' : 'Da fare';
    li.appendChild(badge);
    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.textContent = entry.published ? 'Ripristina' : 'Pubblicato';
    toggle.addEventListener('click', async () => {
      try {
        await sendChange('PATCH', '/api/announcements/' + entry.id, { state: !entry.published });
      } catch (error) { message.textContent = error.message; }
    });
    li.appendChild(toggle);
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.textContent = 'Elimina';
    remove.addEventListener('click', async () => {
      try {
        await sendChange('DELETE', '/api/announcements/' + entry.id);
      } catch (error) { message.textContent = error.message; }
    });
    li.appendChild(remove);
    list.appendChild(li);
  }
}

async function sendChange(method, url, body) {
  const options = { method };
  if (body !== undefined) {
    options.headers = { 'Content-Type': 'application/json' };
    options.body = JSON.stringify(body);
  }
  const response = await fetch(url, options);
  if (!response.ok) {
    const problem = await response.json().catch(() => ({}));
    throw new Error(problem.error || 'Operazione non riuscita.');
  }
  message.textContent = 'Operazione completata.';
  await loadEntries();
}


form.addEventListener('submit', async (event) => {
  event.preventDefault();
  message.textContent = '';
  try {
    const response = await fetch('/api/announcements', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: input.value })
    });
    if (!response.ok) {
      const problem = await response.json().catch(() => ({}));
      throw new Error(problem.error || 'Inserimento non riuscito.');
    }
    input.value = '';
    message.textContent = 'Elemento aggiunto.';
    await loadEntries();
  } catch (error) {
    message.textContent = error.message;
  }
});

document.querySelector('#search').addEventListener('input', () => loadEntries().catch(e => { message.textContent = e.message; }));
loadEntries().catch(error => { message.textContent = error.message; });
