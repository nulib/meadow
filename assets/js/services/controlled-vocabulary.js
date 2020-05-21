/**
 * Prepares React Hook Form array fields of type "Controlled Term"
 * for the form request post shape
 * @param {Array} arr
 * @returns {Array} // Currently the shape the API wants is [ { id: "ABC", role: "act" }]
 */
export function prepControlledTermInput(arr = []) {
  return arr.map(({ id, roleId }) => ({ id, role: roleId }));
}
