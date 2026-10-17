const list = document.querySelector('#entries');
const form = document.querySelector('#entry-form');
const input = document.querySelector('#name');
const message = document.querySelector('#message');

async function loadEntries() {
  const response = await fetch('/api/equipment');
  if (!response.ok) throw new Error('Errore nel caricamento.');
  const entries = await response.json();
  list.replaceChildren();
  for (const entry of entries) {
    const li = document.createElement('li');
    li.className = 'entry-card';
    const content = document.createElement('span');
    content.textContent = entry.name;
    li.appendChild(content);
    const badge = document.createElement('span');
    badge.className = 'status-badge';
    badge.textContent = entry.reserved ? 'Prenotata' : 'Da fare';
    li.appendChild(badge);
    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.textContent = entry.reserved ? 'Ripristina' : 'Prenotata';
    toggle.addEventListener('click', async () => {
      try {
        await sendChange('PATCH', '/api/equipment/' + entry.id, { state: !entry.reserved });
      } catch (error) { message.textContent = error.message; }
    });
    li.appendChild(toggle);
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.textContent = 'Elimina';
    remove.addEventListener('click', async () => {
      try {
        await sendChange('DELETE', '/api/equipment/' + entry.id);
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
    const response = await fetch('/api/equipment', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: input.value })
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

loadEntries().catch(error => { message.textContent = error.message; });
