import React from 'react';
import { Film, Shield, Wrench, Settings } from 'lucide-react';
import { ActiveTab } from '../../types';

interface BottomTabBarProps {
  activeTab: ActiveTab;
  onTabChange: (tab: ActiveTab) => void;
  vaultCount: number;
}

export const BottomTabBar: React.FC<BottomTabBarProps> = ({
  activeTab,
  onTabChange,
  vaultCount,
}) => {
  const tabs = [
    {
      id: 'videos' as ActiveTab,
      label: 'Videos',
      icon: Film,
    },
    {
      id: 'vault' as ActiveTab,
      label: 'Vault',
      icon: Shield,
      badge: vaultCount > 0 ? vaultCount : undefined,
    },
    {
      id: 'tools' as ActiveTab,
      label: 'Tools',
      icon: Wrench,
    },
    {
      id: 'settings' as ActiveTab,
      label: 'Settings',
      icon: Settings,
    },
  ];

  return (
    <nav className="shrink-0 h-16 bg-slate-950/95 dark:bg-slate-950/95 backdrop-blur-md border-t border-slate-800/80 px-2 flex items-center justify-around z-30 select-none">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;

        return (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`flex flex-col items-center justify-center w-16 h-12 rounded-xl transition-all relative ${
              isActive
                ? 'text-violet-400 font-bold'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <div className="relative">
              <Icon
                className={`w-5 h-5 transition-transform duration-200 ${
                  isActive ? 'scale-110 stroke-[2.5]' : 'stroke-[1.8]'
                }`}
              />
              {tab.badge !== undefined && (
                <span className="absolute -top-1 -right-2 px-1 min-w-3.5 h-3.5 rounded-full bg-violet-600 text-[9px] font-bold text-white flex items-center justify-center">
                  {tab.badge}
                </span>
              )}
            </div>
            <span
              className={`text-[10px] mt-1 transition-colors ${
                isActive ? 'text-violet-400 font-bold' : 'text-slate-400 font-medium'
              }`}
            >
              {tab.label}
            </span>
            {isActive && (
              <span className="absolute bottom-1 w-5 h-0.5 rounded-full bg-violet-400 shadow-sm shadow-violet-400/50" />
            )}
          </button>
        );
      })}
    </nav>
  );
};
