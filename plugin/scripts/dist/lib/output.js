// Structured JSON output helpers
export function success(data) {
    console.log(JSON.stringify({ success: true, data }, null, 2));
    process.exit(0);
}
export function failure(error) {
    console.log(JSON.stringify({ success: false, error }, null, 2));
    process.exit(1);
}
