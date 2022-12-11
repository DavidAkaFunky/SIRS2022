import { Router } from 'express';
import { usersRoutes } from './usersRoute';

const router: Router = Router();

router.use('/users', usersRoutes);

export default router;