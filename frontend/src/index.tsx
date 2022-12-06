import React from "react";
import CssBaseline from "@mui/material/CssBaseline";
import { BrowserRouter as Router } from "react-router-dom";
import ReactDOM from "react-dom/client";
import App from "./App";

const root = ReactDOM.createRoot(
	document.getElementById("root") as HTMLElement
);

root.render(
	<Router>
		<React.StrictMode>
      <CssBaseline />
			<App />
		</React.StrictMode>
	</Router>
);
