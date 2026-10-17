const list = document.querySelector('#entries');
const form = document.querySelector('#entry-form');
const input = document.querySelector('#title');
const message = document.querySelector('#message');

async function loadEntries() {
  const response = await fetch('/api/courses');
  if (!response.ok) throw new Error('Errore nel caricamento.');
  const entries = await response.json();
  list.replaceChildren();
  for (const entry of entries) {
    const li = document.createElement('li');
    li.className = 'entry-card';
    const content = document.createElement('span');
    content.textContent = entry.title;
    li.appendChild(content);
    const edit = document.createElement('button');
    edit.type = 'button';
    edit.textContent = 'Modifica';
    edit.addEventListener('click', async () => {
      const newText = window.prompt('Nuovo title', entry.title);
      if (newText === null) return;
      try {
        await sendChange('PUT', '/api/courses/' + entry.id, { title: newText });
      } catch (error) { message.textContent = error.message; }
    });
    li.appendChild(edit);
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.textContent = 'Elimina';
    remove.addEventListener('click', async () => {
      try {
        await sendChange('DELETE', '/api/courses/' + entry.id);
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
    const response = await fetch('/api/courses', {
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

loadEntries().catch(error => { message.textContent = error.message; });
