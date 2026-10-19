import { ApiClient } from '../../../services/apiClient'

// Active courses for the registration picker (mobile-app/lib/services/course_service.dart).
// Never throws: no courses just hides the picker.
export async function fetchActiveCourses() {
  try {
    const body = await ApiClient.get('/api/courses')
    if (!Array.isArray(body)) return []
    return body
      .filter((json) => json && typeof json === 'object')
      .map((json) => ({
        id: String(json._id ?? json.id ?? ''),
        title: String(json.title ?? ''),
        subtitle: String(json.subtitle ?? ''),
      }))
      .filter((course) => course.title !== '')
  } catch (e) {
    console.warn('Courses fetch failed:', e)
    return []
  }
}
