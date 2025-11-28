import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from './ui/alert-dialog';
import { LogOut } from 'lucide-react';

interface LogoutDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
}

export default function LogoutDialogComponent({ open, onOpenChange, onConfirm }: LogoutDialogProps) {
  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="max-w-sm rounded-2xl">
        <AlertDialogHeader className="text-center items-center">
          <div className="w-16 h-16 rounded-full bg-destructive/10 flex items-center justify-center mb-4">
            <LogOut className="w-8 h-8 text-destructive" />
          </div>
          <AlertDialogTitle className="text-2xl">Logout</AlertDialogTitle>
          <AlertDialogDescription className="text-base">
            Are you sure you want to logout? Your progress will be saved, and you can continue learning anytime.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter className="flex-col gap-2 sm:flex-col">
          <AlertDialogAction
            onClick={onConfirm}
            className="w-full h-12 rounded-xl bg-gradient-to-r from-[#CE1126] to-[#FF6B35] text-white"
          >
            Yes, Logout
          </AlertDialogAction>
          <AlertDialogCancel className="w-full h-12 rounded-xl mt-0">
            Cancel
          </AlertDialogCancel>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
