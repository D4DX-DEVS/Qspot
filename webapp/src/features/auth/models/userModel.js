// The signed-in account (mobile-app/lib/screens/auth/model/user_model.dart).
export function userFromJson(json = {}) {
  return {
    id: json.id ?? json._id ?? null,
    phone: String(json.phone ?? json.mobile ?? ''),
    name: json.name == null ? null : String(json.name),
    classNumber: json.class == null ? null : String(json.class),
    email: json.email ?? null,
    role: json.role ?? null,
    dob: json.dob ?? null,
    // True when the server does not say (accounts from before the flag).
    phoneVerified: json.phoneVerified !== false,
    consent: json.consent && typeof json.consent === 'object' ? json.consent : null,
    language: json.language ?? null,
    courseIds: Array.isArray(json.courseIds) ? json.courseIds.map(String) : [],
    token: json.token ?? null,
  }
}

export function userToJson(user) {
  return {
    id: user.id,
    phone: user.phone,
    name: user.name,
    class: user.classNumber,
    email: user.email,
    role: user.role,
    dob: user.dob,
    phoneVerified: user.phoneVerified,
    consent: user.consent,
    language: user.language,
    courseIds: user.courseIds,
    token: user.token,
  }
}
