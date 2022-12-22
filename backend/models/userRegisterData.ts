export default interface UserRegisterData {
    name: string;
    email: string;
    password: string;
    secret?: string;
    token?: string;
}