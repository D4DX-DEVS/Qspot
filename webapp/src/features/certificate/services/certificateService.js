import { ApiClient } from '../../../services/apiClient'
import { certificateFromJson } from '../models/certificateModel'

// Certificates in a `{items: [...]}` body (or a bare list). Revoked ones are
// already left out by the server.
export function parseCertificates(body) {
  const values = Array.isArray(body) ? body : body?.items
  if (!Array.isArray(values)) return []
  return values
    .filter((item) => item && typeof item === 'object')
    .map(certificateFromJson)
    .filter((item) => item.certificateNumber !== '')
}

export const fetchMyCertificates = async () => parseCertificates(await ApiClient.get('/api/certificates/mine'))
