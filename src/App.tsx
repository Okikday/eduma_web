import React from 'react';
import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
  useLocation,
} from 'react-router-dom';
import { ThemeProvider } from './core/theme/themeContext';
import { AssistantHistoryView } from './features/assistant/ui/AssistantHistoryView';
import { AuthProvider, useAuth } from './features/auth/data/AuthContext';
import { ForgotPasswordView } from './features/auth/ui/ForgotPasswordView';
import { SignInView } from './features/auth/ui/SignInView';
import { SignUpView } from './features/auth/ui/SignUpView';
import { VerifyEmailView } from './features/auth/ui/VerifyEmailView';
import { CalendarView } from './features/calendar/ui/CalendarView';
import { LibraryView } from './features/library/ui/LibraryView';
import { NotificationsView } from './features/notifications/ui/NotificationsView';
import {
  LegalDocumentView,
  PremiumView,
  WhatsAppView,
} from './features/profile/ui/AccountSubViews';
import { ProfileView } from './features/profile/ui/ProfileView';
import { HomeTabView } from './features/spaces/ui/HomeTabView';
import {
  JoinByInviteRouteView,
  PinnedSpacesSeeAllView,
  RecentCanvasesSeeAllView,
  RecentSpacesSeeAllView,
} from './features/spaces/ui/SeeAllSpacesViews';
import { SpaceDetailView } from './features/spaces/ui/SpaceDetailView';
import { SpacePageViewer } from './features/spaces/ui/SpacePageViewer';
import { StreakView } from './features/streaks/ui/StreakView';
import { ToastProvider } from './shared/components/AppToast';

function LoadingSplash() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--eduma-bg)]">
      <div className="flex flex-col items-center gap-3">
        <img
          src="/assets/logo/logo.png"
          alt="Eduma"
          className="h-12 w-12 animate-pulse rounded-2xl object-contain"
        />
        <span className="type-label-md text-[var(--eduma-text-muted)]">
          Loading Eduma…
        </span>
      </div>
    </div>
  );
}

function RequireAuth({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) return <LoadingSplash />;
  if (!isAuthenticated) {
    return (
      <Navigate
        to="/sign-in"
        replace
        state={{ from: `${location.pathname}${location.search}` }}
      />
    );
  }
  return <>{children}</>;
}

function RedirectIfAuthed({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) return <LoadingSplash />;
  if (isAuthenticated) return <Navigate to="/main" replace />;
  return <>{children}</>;
}

export function App() {
  return (
    <ThemeProvider>
      <ToastProvider>
        <AuthProvider>
          <BrowserRouter>
            <Routes>
              {/* Public & Auth Routes */}
              <Route
                path="/sign-in"
                element={
                  <RedirectIfAuthed>
                    <SignInView />
                  </RedirectIfAuthed>
                }
              />
              <Route path="/signIn" element={<Navigate to="/sign-in" replace />} />

              <Route
                path="/sign-up"
                element={
                  <RedirectIfAuthed>
                    <SignUpView />
                  </RedirectIfAuthed>
                }
              />
              <Route path="/signUp" element={<Navigate to="/sign-up" replace />} />

              <Route path="/forgot-password" element={<ForgotPasswordView />} />
              <Route
                path="/forgotPassword"
                element={<Navigate to="/forgot-password" replace />}
              />
              <Route path="/reset-password" element={<ForgotPasswordView />} />
              <Route path="/resetPassword" element={<ForgotPasswordView />} />

              <Route path="/verify-email" element={<VerifyEmailView />} />
              <Route path="/verifyEmail" element={<VerifyEmailView />} />

              <Route path="/legalDocument" element={<LegalDocumentView />} />

              {/* Authenticated Main Tabs */}
              <Route
                path="/main"
                element={
                  <RequireAuth>
                    <HomeTabView />
                  </RequireAuth>
                }
              />
              <Route path="/home" element={<Navigate to="/main" replace />} />
              <Route path="/homeTab" element={<Navigate to="/main" replace />} />
              <Route path="/spaceTab" element={<Navigate to="/main" replace />} />

              <Route
                path="/calendarTab"
                element={
                  <RequireAuth>
                    <CalendarView />
                  </RequireAuth>
                }
              />
              <Route
                path="/libraryTab"
                element={
                  <RequireAuth>
                    <LibraryView />
                  </RequireAuth>
                }
              />

              {/* Spaces & Pages */}
              <Route
                path="/spaceDetail"
                element={
                  <RequireAuth>
                    <SpaceDetailView />
                  </RequireAuth>
                }
              />
              <Route
                path="/spaces/:id"
                element={
                  <RequireAuth>
                    <SpaceDetailView />
                  </RequireAuth>
                }
              />
              <Route
                path="/spacePageStatic"
                element={
                  <RequireAuth>
                    <SpacePageViewer />
                  </RequireAuth>
                }
              />
              <Route
                path="/spacePageCanvas"
                element={
                  <RequireAuth>
                    <SpacePageViewer />
                  </RequireAuth>
                }
              />
              <Route
                path="/pageDetails"
                element={
                  <RequireAuth>
                    <SpacePageViewer />
                  </RequireAuth>
                }
              />
              <Route
                path="/join/:code"
                element={
                  <RequireAuth>
                    <JoinByInviteRouteView />
                  </RequireAuth>
                }
              />

              {/* See-All Views */}
              <Route
                path="/pinnedSpacesSeeAll"
                element={
                  <RequireAuth>
                    <PinnedSpacesSeeAllView />
                  </RequireAuth>
                }
              />
              <Route
                path="/recentSpacesSeeAll"
                element={
                  <RequireAuth>
                    <RecentSpacesSeeAllView />
                  </RequireAuth>
                }
              />
              <Route
                path="/recentCanvasesSeeAll"
                element={
                  <RequireAuth>
                    <RecentCanvasesSeeAllView />
                  </RequireAuth>
                }
              />

              {/* Secondary Authenticated Routes */}
              <Route
                path="/notifications"
                element={
                  <RequireAuth>
                    <NotificationsView />
                  </RequireAuth>
                }
              />
              <Route
                path="/streak"
                element={
                  <RequireAuth>
                    <StreakView />
                  </RequireAuth>
                }
              />
              <Route
                path="/assistantHistory"
                element={
                  <RequireAuth>
                    <AssistantHistoryView />
                  </RequireAuth>
                }
              />
              <Route
                path="/profile"
                element={
                  <RequireAuth>
                    <ProfileView />
                  </RequireAuth>
                }
              />
              <Route path="/account" element={<Navigate to="/profile" replace />} />
              <Route
                path="/premium"
                element={
                  <RequireAuth>
                    <PremiumView />
                  </RequireAuth>
                }
              />
              <Route
                path="/whatsapp"
                element={
                  <RequireAuth>
                    <WhatsAppView />
                  </RequireAuth>
                }
              />

              {/* Root & Fallback */}
              <Route path="/" element={<Navigate to="/main" replace />} />
              <Route path="*" element={<Navigate to="/main" replace />} />
            </Routes>
          </BrowserRouter>
        </AuthProvider>
      </ToastProvider>
    </ThemeProvider>
  );
}
export default App;
