export interface CommandResult<T = unknown> {
    success: boolean;
    data?: T;
    error?: string;
}
export declare function success<T>(data: T): never;
export declare function failure(error: string): never;
