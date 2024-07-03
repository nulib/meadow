import * as Dialog from "@radix-ui/react-dialog";
import { styled } from "@stitches/react";

const DialogOverlay = styled(Dialog.Overlay, {
  backgroundColor: "#000a",
  position: "fixed",
  inset: 0,
  zIndex: 9998,
});

const DialogTrigger = styled(Dialog.Trigger, {
  cursor: "pointer",
  border: "none",
  background: "none",
  textTransform: "unset",
});

const DialogContent = styled(Dialog.Content, {
  backgroundColor: "white",
  borderRadius: "3px",
  boxShadow: "5px 5px 13px #0002",
  position: "fixed",
  top: "50%",
  left: "50%",
  transform: "translate(-50%, -50%)",
  width: "90vw",
  maxWidth: "700px",
  maxHeight: "85vh",
  padding: "1rem",
  overflowY: "scroll",
  zIndex: 9999,
});

const DialogClose = styled(Dialog.Close, {
  position: "absolute",
  background: "none",
  border: "none",
  right: "1rem",
  cursor: "pointer",
});

const DialogTitle = styled(Dialog.Title, {
  fontWeight: "700",
});

const DialogFooter = styled(Dialog.Footer, {
  display: "flex",
  justifyContent: "flex-end",
  padding: "1rem",
  borderTop: "1px solid #e5e7eb",
  marginTop: "auto", // Pushes the footer to the bottom of the dialog
});


export {
  DialogClose,
  DialogContent,
  DialogOverlay,
  DialogTitle,
  DialogTrigger,
  DialogFooter
};