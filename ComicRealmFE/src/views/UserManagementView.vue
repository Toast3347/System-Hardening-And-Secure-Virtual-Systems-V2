<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { createUser, deleteUser, getUsers, updateUser } from '@/services/userService'
import { ApiError } from '@/services/httpClient'
import type { RoleName } from '@/types/auth'
import type { CreateUserDto, UpdateUserDto, UserDto } from '@/types/user'

const authStore = useAuthStore()

const users = ref<UserDto[]>([])
const isLoading = ref(false)
const isSubmitting = ref(false)
const isSaving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const editingUserId = ref<number | null>(null)

const createForm = reactive<{
  email: string
  passwordHash: string
  role: RoleName
  isActive: boolean
}>({
  email: '',
  passwordHash: '',
  role: 'Admin',
  isActive: true,
})

const editForm = reactive<{
  email: string
  role: RoleName
  createdBy: number | null
  isActive: boolean
}>({
  email: '',
  role: 'Admin',
  createdBy: null,
  isActive: true,
})

const allowedCreateRoles = computed<RoleName[]>(() => {
  if (authStore.isSuperAdmin) {
    return ['Admin']
  }

  if (authStore.isAdmin) {
    return ['Admin', 'Friend']
  }

  return []
})

const hasUsers = computed(() => users.value.length > 0)

watch(
  allowedCreateRoles,
  (roles) => {
    if (!roles.includes(createForm.role)) {
      createForm.role = roles[0] ?? 'Friend'
    }
  },
  { immediate: true },
)

function normalizeError(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    return error.message
  }

  return fallback
}

async function loadUsers(): Promise<void> {
  isLoading.value = true
  errorMessage.value = ''

  try {
    users.value = await getUsers()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to load users.')
  } finally {
    isLoading.value = false
  }
}

function resetCreateForm(): void {
  createForm.email = ''
  createForm.passwordHash = ''
  createForm.role = allowedCreateRoles.value[0] ?? 'Friend'
  createForm.isActive = true
}

function prepareQuickFriend(): void {
  createForm.role = 'Friend'
}

async function submitCreateUser(): Promise<void> {
  if (!allowedCreateRoles.value.includes(createForm.role)) {
    errorMessage.value = 'Selected role is not allowed for your account.'
    return
  }

  isSubmitting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const payload: CreateUserDto = {
    email: createForm.email,
    passwordHash: createForm.passwordHash,
    role: createForm.role,
    createdBy: authStore.user?.userId ?? null,
    isActive: createForm.isActive,
  }

  try {
    await createUser(payload)
    successMessage.value = 'User created successfully.'
    resetCreateForm()
    await loadUsers()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to create user.')
  } finally {
    isSubmitting.value = false
  }
}

function startEdit(user: UserDto): void {
  editingUserId.value = user.userId
  editForm.email = user.email
  editForm.role = user.role
  editForm.createdBy = user.createdBy
  editForm.isActive = user.isActive
}

function cancelEdit(): void {
  editingUserId.value = null
}

async function submitUpdateUser(userId: number): Promise<void> {
  if (!allowedCreateRoles.value.includes(editForm.role)) {
    errorMessage.value = 'You cannot assign this role.'
    return
  }

  isSaving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const payload: UpdateUserDto = {
    email: editForm.email,
    role: editForm.role,
    createdBy: editForm.createdBy,
    isActive: editForm.isActive,
  }

  try {
    await updateUser(userId, payload)
    successMessage.value = 'User updated successfully.'
    editingUserId.value = null
    await loadUsers()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to update user.')
  } finally {
    isSaving.value = false
  }
}

async function removeUser(userId: number): Promise<void> {
  const shouldDelete = window.confirm('Delete this user?')
  if (!shouldDelete) {
    return
  }

  errorMessage.value = ''
  successMessage.value = ''

  try {
    await deleteUser(userId)
    successMessage.value = 'User deleted successfully.'
    await loadUsers()
  } catch (error) {
    errorMessage.value = normalizeError(error, 'Failed to delete user.')
  }
}

onMounted(async () => {
  await loadUsers()
})
</script>

<template>
  <main class="users-view">
    <section class="panel">
      <h2>User Management</h2>
      <p>Super Admin can create Admin users. Admin can create Admin and Friend users.</p>

      <div class="toolbar" v-if="authStore.isAdmin && allowedCreateRoles.includes('Friend')">
        <button type="button" class="secondary" @click="prepareQuickFriend">Quick add Friend</button>
      </div>

      <form class="form-grid" @submit.prevent="submitCreateUser">
        <label>
          Email
          <input v-model.trim="createForm.email" type="email" required />
        </label>

        <label>
          Password
          <input v-model="createForm.passwordHash" type="password" required />
        </label>

        <label>
          Role
          <select v-model="createForm.role" required>
            <option v-for="role in allowedCreateRoles" :key="role" :value="role">
              {{ role }}
            </option>
          </select>
        </label>

        <label class="checkbox-line">
          <input v-model="createForm.isActive" type="checkbox" />
          Active
        </label>

        <button type="submit" :disabled="isSubmitting || allowedCreateRoles.length === 0">
          {{ isSubmitting ? 'Creating...' : 'Create User' }}
        </button>
      </form>
    </section>

    <section class="panel">
      <h3>Existing Users</h3>

      <p v-if="errorMessage" class="error-text">{{ errorMessage }}</p>
      <p v-if="successMessage" class="success-text">{{ successMessage }}</p>

      <div v-if="isLoading" class="loading-grid" aria-live="polite">
        <div v-for="index in 4" :key="index" class="loading-card"></div>
      </div>

      <div v-else class="table-wrapper">
        <p v-if="!hasUsers" class="empty-state">No users found yet.</p>
        <table>
          <thead>
            <tr>
              <th>Email</th>
              <th>Role</th>
              <th>Active</th>
              <th>Created At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in users" :key="user.userId">
              <template v-if="editingUserId === user.userId">
                <td>
                  <input v-model.trim="editForm.email" type="email" required />
                </td>
                <td>
                  <select v-model="editForm.role">
                    <option v-for="role in allowedCreateRoles" :key="role" :value="role">
                      {{ role }}
                    </option>
                  </select>
                </td>
                <td>
                  <label class="checkbox-line">
                    <input v-model="editForm.isActive" type="checkbox" />
                    Active
                  </label>
                </td>
                <td>{{ new Date(user.createdAt).toLocaleString() }}</td>
                <td class="actions">
                  <button type="button" @click="submitUpdateUser(user.userId)" :disabled="isSaving">
                    Save
                  </button>
                  <button type="button" class="secondary" @click="cancelEdit">Cancel</button>
                </td>
              </template>

              <template v-else>
                <td>{{ user.email }}</td>
                <td>{{ user.role }}</td>
                <td>{{ user.isActive ? 'Yes' : 'No' }}</td>
                <td>{{ new Date(user.createdAt).toLocaleString() }}</td>
                <td class="actions">
                  <button type="button" @click="startEdit(user)">Edit</button>
                  <button
                    type="button"
                    class="danger"
                    @click="removeUser(user.userId)"
                    :disabled="authStore.user?.userId === user.userId"
                  >
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
.users-view {
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

.toolbar {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.8rem;
}

.loading-grid {
  display: grid;
  gap: 0.7rem;
  margin-top: 0.8rem;
}

.loading-card {
  height: 52px;
  border-radius: 10px;
  background: linear-gradient(90deg, var(--surface-alt) 25%, #eef2f7 37%, var(--surface-alt) 63%);
  background-size: 400% 100%;
  animation: shimmer 1.2s ease-in-out infinite;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 0.8rem;
  margin-top: 0.9rem;
}

.form-grid label {
  display: grid;
  gap: 0.3rem;
  font-weight: 600;
}

input,
select,
button {
  font: inherit;
}

input,
select {
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  padding: 0.5rem 0.65rem;
  background: var(--surface-alt);
  color: var(--text);
}

.checkbox-line {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
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
  cursor: not-allowed;
}

.table-wrapper {
  overflow-x: auto;
  margin-top: 0.8rem;
}

.empty-state {
  padding: 0.8rem 0;
  color: var(--muted-text);
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
  gap: 0.5rem;
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
  color: var(--muted-text);
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
