import { TopBar } from "./TopBar";
import { QueueSidebar } from "./QueueSidebar";
import { PreviewArea } from "./PreviewArea";
import { FeedbackPanel } from "./FeedbackPanel";

export function Layout() {
  return (
    <div className="h-screen flex flex-col bg-[#FAFBFE]">
      <TopBar />
      <div className="flex-1 flex min-h-0">
        <QueueSidebar />
        <PreviewArea />
        <FeedbackPanel />
      </div>
    </div>
  );
}
