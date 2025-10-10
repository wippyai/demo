// TODO List Application JavaScript

// Global variables
let currentFilter = 'all';
let editModal;

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Bootstrap modal
    const modalElement = document.getElementById('editModal');
    if (modalElement) {
        editModal = new bootstrap.Modal(modalElement);
    }

    // Load todos on page load
    loadTodos();

    // Setup HTMX event listeners
    setupHTMXListeners();
});

// Setup HTMX event listeners
function setupHTMXListeners() {
    // After successful request, update statistics
    document.body.addEventListener('htmx:afterSwap', function(event) {
        if (event.detail.target.id === 'todos-list') {
            updateStatistics();
            renderTodos();
        }
    });

    // After todo creation, reset form and reload
    document.body.addEventListener('htmx:afterRequest', function(event) {
        if (event.detail.target.id === 'todos-list' && event.detail.successful) {
            const form = document.getElementById('add-todo-form');
            if (form && event.detail.elt === form) {
                loadTodos();
            }
        }
    });
}

// Load todos from API
async function loadTodos() {
    try {
        const response = await fetch('/api/v1/todos');
        const todos = await response.json();

        // Store todos globally
        window.allTodos = todos;

        // Render todos
        renderTodos();

        // Update statistics
        updateStatistics();
    } catch (error) {
        console.error('Failed to load todos:', error);
        showError('Failed to load tasks');
    }
}

// Render todos based on current filter
function renderTodos() {
    const todos = window.allTodos || [];
    const container = document.getElementById('todos-list');

    if (!container) return;

    // Apply filters
    let filteredTodos = todos;

    // Filter by completion status
    if (currentFilter === 'active') {
        filteredTodos = filteredTodos.filter(todo => todo.completed === 0);
    } else if (currentFilter === 'completed') {
        filteredTodos = filteredTodos.filter(todo => todo.completed === 1);
    }

    // Filter by category
    const categoryFilter = document.getElementById('filter-category')?.value.trim();
    if (categoryFilter) {
        filteredTodos = filteredTodos.filter(todo =>
            todo.category && todo.category.toLowerCase().includes(categoryFilter.toLowerCase())
        );
    }

    // Filter by priority
    const priorityFilter = document.getElementById('filter-priority')?.value;
    if (priorityFilter) {
        filteredTodos = filteredTodos.filter(todo => todo.priority === parseInt(priorityFilter));
    }

    // Render
    if (filteredTodos.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="bi bi-inbox"></i>
                <p class="mt-3">No tasks found</p>
            </div>
        `;
    } else {
        container.innerHTML = filteredTodos.map(todo => renderTodoItem(todo)).join('');
    }
}

// Render single todo item
function renderTodoItem(todo) {
    const priorityClass = ['priority-low', 'priority-medium', 'priority-high'][todo.priority - 1];
    const priorityText = ['Low', 'Medium', 'High'][todo.priority - 1];

    const completedClass = todo.completed === 1 ? 'completed' : '';
    const checked = todo.completed === 1 ? 'checked' : '';

    // Format due date
    let dueDateHTML = '';
    if (todo.due_date) {
        const dueDate = new Date(todo.due_date * 1000);
        const now = new Date();
        const diffTime = dueDate - now;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        let dueDateClass = 'due-date';
        if (diffDays < 0) {
            dueDateClass += ' overdue';
        } else if (diffDays <= 2) {
            dueDateClass += ' due-soon';
        }

        dueDateHTML = `
            <div class="${dueDateClass}">
                <i class="bi bi-calendar-event"></i>
                ${formatDate(dueDate)}
                ${diffDays < 0 ? '(Overdue)' : diffDays <= 2 ? '(Due soon)' : ''}
            </div>
        `;
    }

    // Format category
    const categoryHTML = todo.category ?
        `<span class="category-badge me-2"><i class="bi bi-tag"></i> ${escapeHtml(todo.category)}</span>` : '';

    // Format description
    const descriptionHTML = todo.description ?
        `<div class="todo-description">${escapeHtml(todo.description)}</div>` : '';

    return `
        <div class="todo-item ${completedClass}" id="todo-${todo.id}">
            <div class="d-flex align-items-start">
                <div class="form-check me-3">
                    <input class="form-check-input todo-checkbox"
                           type="checkbox"
                           ${checked}
                           onclick="toggleTodo(${todo.id})">
                </div>
                <div class="flex-grow-1">
                    <div class="todo-title">${escapeHtml(todo.title)}</div>
                    ${descriptionHTML}
                    <div class="d-flex gap-2 align-items-center mt-2 flex-wrap">
                        ${categoryHTML}
                        <span class="priority-badge ${priorityClass}">
                            <i class="bi bi-flag-fill"></i> ${priorityText}
                        </span>
                        ${dueDateHTML}
                    </div>
                </div>
                <div class="todo-actions">
                    <button class="btn btn-sm btn-outline-primary" onclick="editTodo(${todo.id})">
                        <i class="bi bi-pencil"></i> Edit
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteTodo(${todo.id})">
                        <i class="bi bi-trash"></i> Delete
                    </button>
                </div>
            </div>
        </div>
    `;
}

// Toggle todo completion
async function toggleTodo(id) {
    try {
        const response = await fetch(`/api/v1/todos/${id}/toggle`, {
            method: 'PATCH'
        });

        if (response.ok) {
            await loadTodos();
        } else {
            showError('Failed to update task');
        }
    } catch (error) {
        console.error('Failed to toggle todo:', error);
        showError('Failed to update task');
    }
}

// Edit todo
async function editTodo(id) {
    const todos = window.allTodos || [];
    const todo = todos.find(t => t.id === id);

    if (!todo) return;

    // Populate form
    document.getElementById('edit-id').value = todo.id;
    document.getElementById('edit-title').value = todo.title;
    document.getElementById('edit-description').value = todo.description || '';
    document.getElementById('edit-category').value = todo.category || '';
    document.getElementById('edit-priority').value = todo.priority;

    if (todo.due_date) {
        const dueDate = new Date(todo.due_date * 1000);
        document.getElementById('edit-due_date').value = formatDateTimeLocal(dueDate);
    } else {
        document.getElementById('edit-due_date').value = '';
    }

    // Show modal
    if (editModal) {
        editModal.show();
    }
}

// Save edited todo
async function saveEdit() {
    const id = document.getElementById('edit-id').value;
    const title = document.getElementById('edit-title').value.trim();
    const description = document.getElementById('edit-description').value.trim();
    const category = document.getElementById('edit-category').value.trim();
    const priority = parseInt(document.getElementById('edit-priority').value);
    const dueDateStr = document.getElementById('edit-due_date').value;

    if (!title) {
        alert('Title is required');
        return;
    }

    const data = {
        title,
        description: description || null,
        category: category || null,
        priority,
        due_date: dueDateStr ? Math.floor(new Date(dueDateStr).getTime() / 1000) : null
    };

    try {
        const response = await fetch(`/api/v1/todos/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            if (editModal) {
                editModal.hide();
            }
            await loadTodos();
        } else {
            showError('Failed to update task');
        }
    } catch (error) {
        console.error('Failed to save todo:', error);
        showError('Failed to update task');
    }
}

// Delete todo
async function deleteTodo(id) {
    if (!confirm('Are you sure you want to delete this task?')) {
        return;
    }

    try {
        const response = await fetch(`/api/v1/todos/${id}`, {
            method: 'DELETE'
        });

        if (response.ok || response.status === 204) {
            await loadTodos();
        } else {
            showError('Failed to delete task');
        }
    } catch (error) {
        console.error('Failed to delete todo:', error);
        showError('Failed to delete task');
    }
}

// Filter todos
function filterTodos(filter) {
    if (filter) {
        currentFilter = filter;

        // Update button states
        document.querySelectorAll('.btn-group .btn').forEach(btn => {
            btn.classList.remove('active');
        });
        event.target.classList.add('active');
    }

    renderTodos();
}

// Update statistics
function updateStatistics() {
    const todos = window.allTodos || [];

    const total = todos.length;
    const completed = todos.filter(t => t.completed === 1).length;
    const active = total - completed;

    document.getElementById('total-count').textContent = total;
    document.getElementById('active-count').textContent = active;
    document.getElementById('completed-count').textContent = completed;
}

// Reset add form
function resetForm() {
    const form = document.getElementById('add-todo-form');
    if (form) {
        form.reset();
        // Reset priority to medium
        document.getElementById('priority').value = '2';
    }
}

// Handle form submission
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('add-todo-form');
    if (form) {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();

            const title = document.getElementById('title').value.trim();
            const description = document.getElementById('description').value.trim();
            const category = document.getElementById('category').value.trim();
            const priority = parseInt(document.getElementById('priority').value);
            const dueDateStr = document.getElementById('due_date').value;

            const data = {
                title,
                description: description || null,
                category: category || null,
                priority,
                due_date: dueDateStr ? Math.floor(new Date(dueDateStr).getTime() / 1000) : null
            };

            try {
                const response = await fetch('/api/v1/todos', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(data)
                });

                if (response.ok) {
                    resetForm();
                    await loadTodos();
                } else {
                    showError('Failed to create task');
                }
            } catch (error) {
                console.error('Failed to create todo:', error);
                showError('Failed to create task');
            }
        });
    }

    // Filter by category on input
    const categoryFilter = document.getElementById('filter-category');
    if (categoryFilter) {
        categoryFilter.addEventListener('input', function() {
            renderTodos();
        });
    }
});

// Utility functions
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(date) {
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatDateTimeLocal(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
}

function showError(message) {
    // Simple alert for now, can be replaced with toast notifications
    alert(message);
}
