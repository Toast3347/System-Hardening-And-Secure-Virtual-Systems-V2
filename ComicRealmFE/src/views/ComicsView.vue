<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { createComic, deleteComic, getComics, updateComic } from '@/services/comicService'
import { ApiError } from '@/services/httpClient'
import type { ComicDto, CreateComicDto, UpdateComicDto } from '@/types/comic'

const authStore = useAuthStore()

const comics = ref<ComicDto[]>([])
const isLoading = ref(false)
const isSubmitting = ref(false)
const isSaving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const editingComicId = ref<number | null>(null)

const createForm = reactive<{
  serie: string
  number: string
  title: string
}>({
  serie: '',
  number: '',
  title: '',
})

const editForm = reactive<{
  serie: string
  number: string
  title: string
}>({
  serie: '',
  number: '',
  title: '',
})

const isAdmin = computed(() => authStore.isAdmin)
const hasComics = computed(() => comics.value.length > 0)

function normalizeError(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    return error.message
  }

  return fallback
}

async function loadComics(): Promise<void> {
  isLoading.value = true
  errorMessage.value = ''

  try {
    comics.value = await getComics()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to load comics.')
  } finally {
    isLoading.value = false
  }
}

function resetCreateForm(): void {
  createForm.serie = ''
  createForm.number = ''
  createForm.title = ''
}

async function submitCreateComic(): Promise<void> {
  if (!isAdmin.value) {
    return
  }

  isSubmitting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const payload: CreateComicDto = {
    serie: createForm.serie,
    number: createForm.number,
    title: createForm.title,
    createdBy: authStore.user?.userId ?? 0,
  }

  try {
    await createComic(payload)
    successMessage.value = 'Comic created successfully.'
    resetCreateForm()
    await loadComics()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to create comic.')
  } finally {
    isSubmitting.value = false
  }
}

function startEdit(comic: ComicDto): void {
  editingComicId.value = comic.comicId
  editForm.serie = comic.serie
  editForm.number = comic.number
  editForm.title = comic.title
}

function cancelEdit(): void {
  editingComicId.value = null
}

async function submitUpdateComic(comicId: number): Promise<void> {
  isSaving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const payload: UpdateComicDto = {
    serie: editForm.serie,
    number: editForm.number,
    title: editForm.title,
  }

  try {
    await updateComic(comicId, payload)
    successMessage.value = 'Comic updated successfully.'
    editingComicId.value = null
    await loadComics()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to update comic.')
  } finally {
    isSaving.value = false
  }
}

async function removeComic(comicId: number): Promise<void> {
  if (!isAdmin.value) {
    return
  }

  const shouldDelete = window.confirm('Delete this comic?')
  if (!shouldDelete) {
    return
  }

  errorMessage.value = ''
  successMessage.value = ''

  try {
    await deleteComic(comicId)
    successMessage.value = 'Comic deleted successfully.'
    await loadComics()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to delete comic.')
  }
}

onMounted(async () => {
  await loadComics()
})
</script>

<template>
  <main class="comics-view">
    <section class="panel">
      <h2>Comics</h2>
      <p v-if="isAdmin">You can create, update, and delete comics.</p>
      <p v-else>Read-only view for Friend role.</p>

      <form v-if="isAdmin" class="form-grid" @submit.prevent="submitCreateComic">
        <label>
          Serie
          <input v-model.trim="createForm.serie" type="text" required />
        </label>

        <label>
          Number
          <input v-model.trim="createForm.number" type="text" required />
        </label>

        <label>
          Title
          <input v-model.trim="createForm.title" type="text" required />
        </label>

        <button type="submit" :disabled="isSubmitting">
          {{ isSubmitting ? 'Creating...' : 'Create Comic' }}
        </button>
      </form>
    </section>

    <section class="panel">
      <p v-if="errorMessage" class="error-text">{{ errorMessage }}</p>
      <p v-if="successMessage" class="success-text">{{ successMessage }}</p>

      <div v-if="isLoading" class="loading-grid" aria-live="polite">
        <div v-for="index in 3" :key="index" class="loading-card"></div>
      </div>

      <div v-else class="table-wrapper">
        <p v-if="!hasComics" class="empty-state">No comics available yet.</p>
        <table>
          <thead>
            <tr>
              <th>Serie</th>
              <th>Number</th>
              <th>Title</th>
              <th>Updated At</th>
              <th v-if="isAdmin">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="comic in comics" :key="comic.comicId">
              <template v-if="isAdmin && editingComicId === comic.comicId">
                <td><input v-model.trim="editForm.serie" type="text" required /></td>
                <td><input v-model.trim="editForm.number" type="text" required /></td>
                <td><input v-model.trim="editForm.title" type="text" required /></td>
                <td>{{ new Date(comic.updatedAt).toLocaleString() }}</td>
                <td class="actions">
                  <button type="button" @click="submitUpdateComic(comic.comicId)" :disabled="isSaving">
                    Save
                  </button>
                  <button type="button" class="secondary" @click="cancelEdit">Cancel</button>
                </td>
              </template>

              <template v-else>
                <td>{{ comic.serie }}</td>
                <td>{{ comic.number }}</td>
                <td>{{ comic.title }}</td>
                <td>{{ new Date(comic.updatedAt).toLocaleString() }}</td>
                <td v-if="isAdmin" class="actions">
                  <button type="button" @click="startEdit(comic)">Edit</button>
                  <button type="button" class="danger" @click="removeComic(comic.comicId)">
                    Delete
                  </button>
                </td>
              </template>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </main>
</template>

<style scoped>
.comics-view {
  display: grid;
  gap: 1rem;
}

.panel {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1rem;
}

.panel p {
  color: var(--muted-text);
}

.loading-grid {
  display: grid;
  gap: 0.7rem;
  margin-top: 0.8rem;
}

.loading-card {
  height: 56px;
  border-radius: 10px;
  background: linear-gradient(90deg, var(--surface-alt) 25%, #eef2f7 37%, var(--surface-alt) 63%);
  background-size: 400% 100%;
  animation: shimmer 1.2s ease-in-out infinite;
}

.empty-state {
  padding: 0.8rem 0;
  color: var(--muted-text);
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 0.8rem;
  margin-top: 0.8rem;
}

.form-grid label {
  display: grid;
  gap: 0.3rem;
  font-weight: 600;
}

input,
button {
  font: inherit;
}

input {
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  padding: 0.5rem 0.65rem;
  background: var(--surface-alt);
  color: var(--text);
}

button {
  border: none;
  border-radius: 8px;
  background: var(--accent);
  color: #fff;
  padding: 0.5rem 0.7rem;
  cursor: pointer;
}

button.secondary {
  background: var(--surface-alt);
  color: var(--text);
  border: 1px solid var(--border-strong);
}

button.danger {
  background: var(--danger);
}

button:disabled {
  opacity: 0.6;
}

.table-wrapper {
  overflow-x: auto;
  margin-top: 0.8rem;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th,
td {
  border-bottom: 1px solid var(--border);
  text-align: left;
  padding: 0.7rem;
}

.actions {
  display: flex;
  gap: 0.45rem;
}

.error-text {
  color: var(--danger);
  margin-top: 0.4rem;
}

.success-text {
  color: var(--success);
  margin-top: 0.4rem;
}

.muted {
  margin-top: 0.5rem;
}

@keyframes shimmer {
  0% {
    background-position: 100% 0;
  }

  100% {
    background-position: 0 0;
  }
}
</style>
